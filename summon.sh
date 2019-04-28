#!/bin/bash
## summon --- assemble user config files (aka dotfiles) on Unix-like systems
#
# Copyright (C) 2018 Guilherme Gondim
#
# Website: https://gitlab.com/semente/summon
# Keywords: dotfiles, cli, bash
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# exit on first error
set -e

# meta data
readonly PROGNAME=summon
readonly VERSION="0.1"
readonly WEBSITE="https://github.com/semente/summon"
readonly AUTHOR="Guilherme Gondim"
readonly COPYRIGHT="Copyright (C) 2018 by $AUTHOR"

# default settings
VERSION_CONTROL=numbered
LN_ARGS=()

# load custom settings
# XXX: undocumented; use carefully
for summonrc in ".summonrc" "${XDG_CONFIG_HOME:-${HOME}/.config}/summon/summonrc" "${HOME}/.summonrc"; do
    if [ -f "$summonrc" ]; then
        # shellcheck source=/dev/null
        source "$summonrc"
        break
    fi
done

export VERSION_CONTROL          # see ln(1) manpage

# internal use
_LINK_METHOD=(--symbolic --relative)

function print_version() {
    echo "$PROGNAME version $VERSION"
    echo "$COPYRIGHT"
    echo
    echo "$PROGNAME comes with ABSOLUTELY NO WARRANTY.  This is free software, and"
    echo "you are welcome to redistribute it under certain conditions.  See the"
    echo "GNU General Public Licence version 3 for details."
}

function print_usage() {
    echo "Usage: $PROGNAME [OPTION]... TARGET..."
    echo "Try \`$0 -h' for more information."
}

function print_help() {
    print_version
    echo
    print_usage | head -1
    echo "Assemble user config files (aka dotfiles) on Unix-like systems."
    echo
    echo " Examples:"
    echo
    echo "  summon my-dotfiles"
    echo "  summon dotfiles/zsh dotfiles/tmux"
    echo "  summon dotfiles/*"
    echo "  summon dotfiles/$(hostname)/* dotfiles/common/*"
    echo "  summon -H dotfiles/bash dotfiles/screen  # use hard links"
    echo "  summon -b off dotfiles/work/*            # disable backups"
    echo
    echo " Options:"
    echo
    echo "  -H                      make hard links instead of symbolic links"
    echo "  -b BACKUP-METHOD        choose between numbered (default), simple or off"
    echo "  -v                      verbose (i.e. give more information during processing)"
    echo "  -d                      print commands as they are executed (for debug)"
    # echo "  -n                      read commands but do not execute them (dry run)"
    echo "  -V                      print version number"
    echo "  -h                      show this help text"
    echo
    echo "See <$WEBSITE> for more information or bug reports."
}

function message() {
    # pretty-print messages of arbitrary length
    local message="$PROGNAME: $*"
    echo "$message" | fold -s -w ${COLUMNS:-80} >&2
}

function errormsg() {
    # exit script with error
    message "${*:-unknown error}"
    print_usage
    exit 1
}

function parse_command_line() {
    local option backup_method
    while getopts HvdnVhb: option; do
        case $option in
            H)                  # use hard links
                _LINK_METHOD=() # empty. ln default method is to use hard links
                ;;
            v)                  # verbose
                VERBOSE=1
                LN_ARGS+=(--verbose)
                ;;
            d)                  # debug
                set -x
                ;;
            n)                  # dry run
                errormsg "dry run \(-n\) not implemented yet"
                #set -vn
                ;;
            V)                  # version
                print_version && exit
                ;;
            h)                  # help
                print_help && exit
                ;;
            b)                  # backup method
                backup_method="$OPTARG"
                export VERSION_CONTROL=$backup_method
                ;;
            *)                  # invalid option
                exit 1
        esac
    done
    shift $((OPTIND - 1))

    local argnum=$#
    if [ "$argnum" -lt 1 ]; then
        errormsg "missing target operand"
    fi
    
    TARGETS=( "$@" )
}

function summon_file() {
    # Create links to the dotfiles into $HOME

    local hardlink_count
    local target="$1"
    local link_name="${target/#.\//$HOME\/}"

    # ignore if the symlink is already installed
    if [ -e "$link_name" ]; then
        hardlink_count="$(stat -c %h -- "$link_name")"
        if [ -L "$link_name" ] || [ "$hardlink_count" -gt 1 ]; then
            cmp --quiet "$target" "$link_name" && {
                test -n $VERBOSE && message "skipping ${link_name} - The link is already created"
                return
            }
        fi
    fi

    ln --backup "${LN_ARGS[@]}" "${_LINK_METHOD[@]}" "$target" "$link_name"
}

function summon_dir() {
    # Find dotfiles to be installed on target directory

    local dotfiles
    local target="$1"

    if [ -d "$target" ]; then
        (
            # using a ( subshell ) to avoid having to cd back
            cd "$target"
            
            # make missing target directories in advance
            find . \( -path "*/.git" -o -path "*/.stversions" \) -prune -o -type d \
                | sed "s:^\.:$HOME:g" \
                | xargs mkdir -p
            
            dotfiles=$(find . \( -name "*~" -o -name "#*" \) -prune -o -type f)
            for dotfile in $dotfiles; do
                 summon_file "$dotfile"
            done
        )
    fi
}

function main() {
    parse_command_line "$@"

    for target in "${TARGETS[@]}"; do
        summon_dir "$target"
    done 
}

main "$@"
