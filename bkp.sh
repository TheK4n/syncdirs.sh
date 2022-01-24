
BACKUP_DIR="$HOME"/.backup
BACKUP_DIR_1="$BACKUP_DIR"/1
BACKUP_DIR_2="$BACKUP_DIR"/2
MEDIA_BACKUP="/media/backup"
GPG_ID="$BACKUP_DIR"/.gpg-id



die() {
	echo "$@" >&2
	exit 1
}

yesno() {
	[[ -t 0 ]] || return 0
	local response
	read -r -p "$1 [y/N] " response
	[[ $response == [yY] ]] || exit 1
}

cmd_init() {
    mkdir -p "$BACKUP_DIR"/1 || true
    ln -s $MEDIA_BACKUP "$BACKUP_DIR_2" || die "not mounted $MEDIA_BACKUP"
    echo $1 > "$GPG_ID"
}

cmd_insert() {

    [[ "${1:0:1}" == [/~.] ]] && die "you cant use absolute path"
    
    [[ -e "$BACKUP_DIR_1"/"$1" ]] && die "already exists"
    [[ -e "$BACKUP_DIR_2"/"$1" ]] && die "already exists"
    [[ -e "$BACKUP_DIR_1"/"$1".bkp ]] && die "already exists"
    [[ -e "$BACKUP_DIR_2"/"$1".bkp ]] && die "already exists"

    local enc_file_name
    mkdir -p "$BACKUP_DIR_1"/"$(dirname $1)" && echo "created directory: $BACKUP_DIR_1/$(dirname $1)"
    enc_file_name="$BACKUP_DIR_1"/"$(dirname $1)"/"$(basename $1)".bkp

    if [ -d "$1" ]
    then
        tar czf - "$1"/* | gpg -e -R "$(cat $GPG_ID)" > "$enc_file_name"
    else
        tar czf - "$1" | gpg -e -R "$(cat $GPG_ID)" > "$enc_file_name"
    fi

    cp -R $(dirname "$enc_file_name") "$BACKUP_DIR_2"
}

cmd_delete() {
   
    if [ -d "$BACKUP_DIR_1"/"$1" ]
    then
        rm -r "$BACKUP_DIR_1"/"$1"
    else
        rm "$BACKUP_DIR_1"/"$1".bkp
    fi
    
    if [ -d "$BACKUP_DIR_2"/"$1" ]
    then
        rm -r "$BACKUP_DIR_2"/"$1"
    else
        rm "$BACKUP_DIR_2"/"$1".bkp
    fi
}


cmd_show() {
    echo "Backup"
    tree "$BACKUP_DIR_1"
}


cmd_restore() {

    if [ -d "$BACKUP_DIR_1"/"$1" ]
    then
        echo no
    else
        filename_="$(basename "$1")"
        filename_="${filename%.*}"
        echo $filename_
        mkdir -p "$(dirname "$1")"
        gpg -d "$BACKUP_DIR_1"/"$1".bkp | tar xzf - | "$(dirname "$1")"/"$filename_"
    fi

}

cmd_diskusage() {
    if [ -d "$BACKUP_DIR_1"/"$1" ]
    then
        du -hs "$BACKUP_DIR_1"/"$1"
        du -hs "$BACKUP_DIR_2"/"$1"
    else
        du -hs "$BACKUP_DIR_1"/"$1".bkp
        du -hs "$BACKUP_DIR_2"/"$1".bkp
    fi

}


case "$1" in
	init) shift;			    cmd_init    "$@" ;;
	help|--help) shift;		    cmd_usage   "$@" ;;
	version|--version) shift;	cmd_version "$@" ;;
	show|ls|list) shift;		cmd_show    "$@" ;;
	find|search) shift;		    cmd_find    "$@" ;;
	grep) shift;			    cmd_grep    "$@" ;;
	insert|add) shift;		    cmd_insert  "$@" ;;
    restore) shift;             cmd_restore "$@" ;;
	delete|rm|remove) shift;	cmd_delete  "$@" ;;
	du) shift;	                cmd_diskusage  "$@" ;;
	*)				            cmd_show    "$@" ;;
esac
exit 0
