
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

    test -d "$1" && die "only files, not directory"

    test -f "$BACKUP_DIR_1/$(basename "$1")" && die "'$(basename "$1")' already exists"

    file_name="$(basename "$1")"
    gpg -e -R "$(cat "$GPG_ID")" -o "$BACKUP_DIR_1"/"$file_name" "$1"
    cmd_rsync_all
}

cmd_delete() {
    file_name="$(basename "$1")"
    rm "$BACKUP_DIR_1"/"$file_name"
    rm "$BACKUP_DIR_2"/"$file_name" && \
    echo "$SCRIPT_NAME: '$BACKUP_DIR_1/$file_name' Removed"
}

cmd_show() {
    echo "Backup"
    tree "$BACKUP_DIR_1" | tail -n +2
}

cmd_restore() {
    file_name=$(basename "$1")
    test -e "$BACKUP_DIR_1"/"$1" && gpg -d "$BACKUP_DIR_1"/"$1" > "$file_name"
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
    less "$LOG_FILE"
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
