#!/usr/bin/env bash

BACKUP_DIR="$HOME"/.backup
BACKUP_DIR_1="$BACKUP_DIR"/1  # local file system

BACKUP_FILE="$BACKUP_DIR/backup.conf"
LOG_FILE="$BACKUP_DIR/backup.log"

SCRIPT_NAME="$(basename "$0")"


die() {
    echo "$SCRIPT_NAME: Error: $1" >&2
    exit 1
}

yesno() {
    [[ -t 0 ]] || return 0
    local response
    read -r -p "$1 [y/N] " response
    [[ $response == [yY] ]] || exit 1
}

log_msg() {
    echo "$SCRIPT_NAME: $(date +"%d-%m-%Y %T"): $1" >> "$LOG_FILE"
}

log_error() {
    log_msg "Error: $1"
}

get_filesystems() {
    find -L "$BACKUP_DIR" -maxdepth 1 -type d | grep -vE "^$BACKUP_DIR$" | sort
}

cmd_init() {

    mkdir -p "$BACKUP_DIR"/1 || true
    touch "$LOG_FILE"
    touch "$BACKUP_FILE"
}

rsync_with() {
    rsync -ra "$BACKUP_DIR_1"/* "$1" && rsync -ra "$1"/* "$BACKUP_DIR_1"
}

cmd_rsync_all() {
    for i in $(get_filesystems)
    do
        rsync_with "$i"
    done
}

cmd_insert() {
    test -e "$1" || die "not exists"
    test -d "$1" && die "only files, not directory"

    _path="$BACKUP_DIR_1/$(basename "$1")/$(date +"%d-%m-%y")"
    file_name="$_path/$(date +"%H:%M:%S")"

    test -f "$file_name" && die "'$(basename "$1")' already exists"

    mkdir -pv "$_path"
    gpg -c -o "$file_name" "$1"
    cmd_rsync_all
}

delete_if_exists() {
    if [ -d "$1" ]; then
        rm -r "$1"
    elif [ -f "$1" ]; then
        rm "$1"
    else
        return 1
    fi
}

cmd_delete() {
    yesno "Remove '$1'?"
    for i in $(get_filesystems)
    do
        _file="$i"/"$1"
        delete_if_exists "$_file" && echo "$SCRIPT_NAME: '$_file' Removed"
    done
}

cmd_show() {

    test -n "$1" && __FILE="$1"

    test -z "$2" && LEVEL=1 || LEVEL="$2"
    test "$LEVEL" -lt 0 2>/dev/null && die "Level must be positive integer"
    test "$LEVEL" -gt 3 2>/dev/null && die "Max level 3"

    echo "Backup"
    tree -L "$LEVEL" "$BACKUP_DIR_1/$__FILE" | tail -n +2 | head -n -2  # tree exclude first and last lines
}

cmd_restore() {
    test -e "$1" && die "'$1' exists in current directory"
    file_name="$(basename "$1")"

    # get last saved file by time
    last_sub_dir="$(ls -t "$BACKUP_DIR_1"/"$file_name" | head -n 1)"
    last_file="$BACKUP_DIR_1"/"$file_name"/"$last_sub_dir"/"$(ls -t "$BACKUP_DIR_1"/"$file_name"/"$last_sub_dir" | head -n 1)"

    # restore last saved file
    test -e "$last_file" && gpg -d -o "$file_name" "$last_file"
}

cmd_diskusage() {
    for i in $(get_filesystems)
    do
        du -hs "$i"/"$1"
    done
}

cmd_register() {
    if [ -f "$1" ]; then
        realpath "$1" >> "$BACKUP_FILE"
        log_msg "Register '$(realpath "$1")'"
        sort "$BACKUP_FILE" | uniq > "$BACKUP_DIR"/.tmp  # delete duplicates
        cat "$BACKUP_DIR"/.tmp > "$BACKUP_FILE"
    else
        log_error "'$1' not a file"
    fi
}

cmd_registered() {
    cat "$BACKUP_FILE"
}

cmd_cron() {
    for i in $(tr '\n' ' ' < "$BACKUP_FILE");
    do
        if [ -f "$i" ] 
        then
            cmd_insert "$i" > /dev/null
            log_msg "Backup '$i'"
        else
            log_error "'$i' not exists"
        fi
    done
}

cmd_regedit() {
    $EDITOR "$BACKUP_FILE"
}

cmd_log() {
    cat "$LOG_FILE"
}

cmd_inspect() {
    file_name="$BACKUP_DIR_1/$1"
    test -e "$file_name"
    echo "$1 $(du -hs "$file_name" | head -n 1 | awk '{printf $1}') $(ls "$file_name" | wc -l)"
}

cmd_usage() {
	echo
	cat <<-_EOF
	Usage:
        init: initialize
        add: add files to backup
        ls: show all files
        sync: syncronize files
        restore: copy file to workdir
        rm: delete file from backup
        du: disk usage
        reg: register file to backup by cron
        cron: copy all files registered
	_EOF
}

cmd_extension_or_show() {
    if [ -z "$1" ]; then
        cmd_show "$@"
    else
        cmd_usage
    fi
}

case "$1" in
    init) shift;               cmd_init    "$@" ;;
    help|--help) shift;        cmd_usage   "$@" ;;
    #version|--version) shift;  cmd_version "$@" ;;
    ls) shift;       cmd_show    "$@" ;;
    add) shift;         cmd_insert  "$@" ;;
    sync) shift;               cmd_rsync_all   "$@" ;;
    restore) shift;            cmd_restore "$@" ;;
    rm) shift;   cmd_delete  "$@" ;;
    du) shift;                 cmd_diskusage  "$@" ;;
    reg) shift;       cmd_register "$@" ;;
    registered) shift;         cmd_registered "$@" ;;
    regedit) shift;            cmd_regedit "$@" ;;
    cron) shift;               cmd_cron     "$@" ;;
    log) shift;                cmd_log      "$@" ;;
    inspect) shift;            cmd_inspect  "$@" ;;

    *)                         cmd_show    "$@" ;;
esac
exit 0
