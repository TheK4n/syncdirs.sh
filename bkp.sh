
BACKUP_DIR="$HOME"/.backup
BACKUP_DIR_1="$BACKUP_DIR"/1
BACKUP_DIR_2="$BACKUP_DIR"/2
MEDIA_BACKUP="/media/backup"
GPG_ID="$BACKUP_DIR"/.gpg-id

BACKUP_FILE="$BACKUP_DIR/backup.conf"
LOG_FILE="$BACKUP_DIR/backup.log"

SCRIPT_NAME="$(basename "$0")"


die() {
	echo "$SCRIPT_NAME: Error: $1" >&2
	exit 1
}

log_msg() {
    echo "$SCRIPT_NAME: $(date +"%d-%m-%Y %T"): $1" >> "$LOG_FILE"
}

log_error() {
    log_msg ": Error: $1"
}

cmd_init() {

    test -z "$(gpg -k | grep "$1")" && die "No public key '$1'"
    test -z "$(gpg -K | grep "$1")" && die "No private key '$1'"

    mkdir -p "$BACKUP_DIR"/1 || true
    touch "$LOG_FILE"
    touch "$BACKUP_FILE"
    ln -s $MEDIA_BACKUP "$BACKUP_DIR_2" || die "not mounted '$MEDIA_BACKUP'"
    echo "$1" > "$GPG_ID"
}

cmd_rsync_all() {
    rsync -ra "$BACKUP_DIR_1"/* "$BACKUP_DIR_2" && rsync -ra "$BACKUP_DIR_2"/* "$BACKUP_DIR_1"
}

cmd_insert() {
    test -e "$1" || die "not exists"
    test -d "$1" && die "only files, not directory"

    _path="$BACKUP_DIR_1/$(basename "$1")/$(date +"%d-%m-%y")"
    file_name="$_path/$(date +"%H:%M:%S")"

    test -f "$file_name" && die "'$(basename "$1")' already exists"

    mkdir -pv "$_path"
    gpg -e -R "$(cat "$GPG_ID")" -o "$file_name" "$1"
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
    _path="$BACKUP_DIR_1"/"$1"
    _path2="$BACKUP_DIR_2"/"$1"
    delete_if_exists "$_path" && echo "$SCRIPT_NAME: '$_path' Removed"
    delete_if_exists "$_path2" && echo "$SCRIPT_NAME: '$_path2' Removed"
}

cmd_show() {
    echo "Backup"
    tree "$BACKUP_DIR_1" | tail -n +2
}

_get_last_file_by_time() {
    true
}

cmd_restore() {
    file_name="$(basename "$1")"
    last_sub_dir="$(ls -t "$BACKUP_DIR_1"/"$file_name" | head -n 1)"
    last_file="$BACKUP_DIR_1"/"$file_name"/"$last_sub_dir"/"$(ls -t "$BACKUP_DIR_1"/"$file_name"/"$last_sub_dir" | head -n 1)"
    test -e "$last_file" && gpg -d "$last_file" > "$file_name"
}

cmd_diskusage() {
    du -hs "$BACKUP_DIR_1"/"$1"
    du -hs "$BACKUP_DIR_2"/"$1"
}

cmd_register() {
    if [ -f "$1" ]; then
        realpath "$1" >> "$BACKUP_FILE"
        log_msg "Register '$(realpath "$1")'"
    else
        log_error "'$1' not a file"
    fi
}

cmd_registered() {
    cat "$BACKUP_FILE"
}

cmd_cron() {
    for i in $(cat "$BACKUP_FILE" | tr '\n' ' ');
    do
        if [ -f "$i" ] 
        then
            cmd_insert "$i"
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


case "$1" in
	init) shift;			          cmd_init    "$@" ;;
	#help|--help) shift;		     cmd_usage   "$@" ;;
	#version|--version) shift;	 cmd_version "$@" ;;
	show|ls|list) shift;		    cmd_show    "$@" ;;
	#find|search) shift;		     cmd_find    "$@" ;;
	#grep) shift;			           cmd_grep    "$@" ;;
	insert|add) shift;		      cmd_insert  "$@" ;;
  sync) shift;                cmd_rsync_all   "$@" ;;
  restore) shift;             cmd_restore "$@" ;;
	delete|rm|remove) shift;   	cmd_delete  "$@" ;;
	du) shift;	                cmd_diskusage  "$@" ;;
  register|reg) shift;        cmd_register "$@" ;;
  registered) shift;          cmd_registered "$@" ;;
  regedit) shift;             cmd_regedit "$@" ;;
  cron) shift;                cmd_cron     "$@" ;;
  log) shift;                 cmd_log      "$@" ;;

	*)				                  cmd_show    "$@" ;;
esac
exit 0
