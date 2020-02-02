#!/usr/bin/env bash

#title         : notes.sh
#description   : A script for managing notes and journal entries
#author		   : Sam Westwood (samyules@gmail.com) 
#date          : Thu Jan 30 17:42:18 MST 2020
#version       : Alpha 0.1
#usage		   : notes.sh -flag [-Category] <Title. Note.> 
#notes         : 
#bash_version  : 5.0.11(1)-release (x86_64-apple-darwin18.6.0)
#==============================================================================

notes_dir="${configured_dir:-$HOME/notes}"

# Check to see if notes directory exists, and create if needed
if ! $(mkdir -p "$notes_dir"); then
    echo "Could not create directory $notes_dir, please update your \$NOTES_DIRECTORY" >&2
    exit 1
fi

# If no $EDITOR, look for `editor` (symlink on debian/ubuntu/etc)
if [ -z "$EDITOR" ] && type editor &>/dev/null; then
    EDITOR=editor
fi

file_name=""

new_note() {
    local note_category=""
    local note_tags=""
    local note_name="$*"
    local note_title=""
    local note_content=""
    local note_date=$(date +"%F %T %z")

    if [[ -z $note_name ]]; then
        printf "Please enter the name of the note.\n\n"
        usage
    fi

    ## Check for if category exists, denoted by a word preceded by a '-'
    if [[ $note_name =~ ^\-[[:print:]] ]]; then     # This statement checks to see if the first character is a .(period)
        set -- $note_name
        note_category="${1#"-"}"                    # '#"-" strips the '-' from the begining of the first word and assigns it to a var 
        
        ## create directory for note_category if it doesn't exist, and exit gracefully on error.
        if ! $(mkdir -p "$notes_dir/$note_category"); then
            printf "Could not create category directory $notes_dir/$note_category. Please update your \$NOTES_DIRECTORY" >&2
            exit 1
        fi

        shift
        note_name=$*                                # the remainder of the string is assigned to note_name
    fi

    # Separates the note content from the title (note_name)
    # note_name is the first sentence. Content follows
    note_content=${note_name#*." "}                 # Removes the first sentence from the string, leaving only the note content
    note_name=${note_name%%". "*}                   # Removes the everything after the first sentence, leaving only the name.

    # Actions to take if $note_category exists
    if [[ -z $note_category ]]; then
        note_category="quicknotes" 
    fi
    
    # Generate file name from $note_name and other actions to take to create file
    file_name=${note_name// /_}                     # replaces spaces in the note name with underscores
    file_name=${file_name%"."}                      # remove trailing period '.'
    file_name=${file_name,,}                        # make file_name all lowercase    

    # For single sentence notes, $note_content is assigned the value of $note_name
    if [[ -z $note_content ]]; then
        note_content="$note_name"
    fi

    # Output content
    cat <<EOF > $notes_dir/$note_category/$file_name.md
---
title: $note_name
category: $note_category
tags: $note_tags
date: $note_date
---

# $note_name

$note_content

EOF

sleep 1

open_note $notes_dir/$note_category/$file_name.md

}

open_note() {
    
    local note_path=$1

    if [ -z "$EDITOR" ]; then
        printf "Please set \$EDITOR to edit notes\n"
        exit 1
    fi

    case "$EDITOR" in
        "vi"|"vim"|"nvim" )
            $EDITOR +10 "+normal $" "$note_path" < /dev/tty
            ;;
        * )
            $EDITOR "$note_path" < /dev/tty
            ;;
    esac
}


usage() {
    local name=$(basename $0)
	cat <<EOF

$name is a command line note taking tool.

Usage:
    $name new|n|-n [-Category] <name>                 # Create a new note
    $name --help|-help|-h                 # Show this list

command|c means you can use 'command' or equivalent shorthand 'c'

EOF
}


main() {
    ret=0
    local cmd=""

    if [ -z "$1" ]; then
        printf "No command specified.\n\n"
        usage
        exit 1
    fi

    case "$1" in
        "new"|"n"|"-n" )
            cmd="new_note"
            ;;
        "--help"|"-help"|"-h" )
            cmd="usage"
            ;;
        * )
            printf "$1 is not a recognized notes command.\n\n"
            command="usage"
            ret=1
            ;;
    esac
    shift

    $cmd "$@"
    ret=$[$ret+$?]
    exit $ret
}

main "$@"
