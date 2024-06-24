#!/usr/bin/env bash


set -ueo pipefail
shopt -s nullglob

load_config() {
    source ./example_config.sh
}

_is_variable_set() {
    [[ -v "$1" ]]
}

_is_directory() {
    [[ -d "$1" ]]
}

_directory_writable() {
    [[ -w "$1" ]]
}

get_backup_dirs() {
    echo "${BACKUP_DIRECTORIES[*]}"
}

_check_backup_dirs() {
    local backup_dir count
    count=0
    for backup_dir in $(get_backup_dirs)
    do
        if ! _is_directory "$backup_dir"; then
            echo "Config is invalid: BACKUP_DIRECTORIES[$count] is not a directory"
            exit 1
        fi
        if ! _directory_writable "$backup_dir"; then
            echo "Config is invalid: BACKUP_DIRECTORIES[$count] is not writable"
            exit 1
        fi
        count="(($count+1))"
    done
}

check_config() {
    if ! _is_variable_set "ROOT_BACKUP_DIRECTORY"; then
        echo "Config is invalid: variable ROOT_BACKUP_DIRECTORY not set"
        exit 1
    fi

    if ! _is_variable_set "BACKUP_DIRECTORIES"; then
        echo "Config is invalid: variable BACKUP_DIRECTORIES not set"
        exit 1
    fi

    if ! _is_directory "$ROOT_BACKUP_DIRECTORY"; then
        echo "Config is invalid: ROOT_BACKUP_DIRECTORY(=$ROOT_BACKUP_DIRECTORY) is not a directory"
        exit 1
    fi

    _check_backup_dirs
}

sync_root_with() {
    rsync -ra "$ROOT_BACKUP_DIRECTORY"/* "$ROOT_BACKUP_DIRECTORY"/.* "$1"
}

cmd_sync_all() {
    for i in $(get_backup_dirs)
    do
        sync_root_with "$i"
    done
}


load_config
check_config


case "$1" in
    sync) shift;  cmd_sync_all ;;

    *)            echo sad    ;;
esac
exit 0