#!/usr/bin/env bash

#### Template Begin
# Slightly adapted from: https://sharats.me/posts/shell-script-best-practices/

# exit if a command fails
set -o errexit

# fail when setting an unset variable
# to access variables not set yet use "${VARNAME-}"
set -o nounset

# treat pipe as failed even if one command fails
set -o pipefail

# enable debug mode when script is ran like 
# `TRACE=1 ./install.sh [folder]`
if [[ -n "${TRACE-}" ]]; then
	set -o xtrace
fi

# Change to directory the script is located in when ran
#cd "$(dirname "$0")"

#### Template End

locate_firefox_dir() {
   # possible firefox directory locations on Linux
   # TODO: add possible locations on MacOS
   possible_locations=("$HOME/snap/firefox/common/.mozilla/firefox" "$HOME/.mozilla/firefox" "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" )
   for i in "${possible_locations[@]}"; do
      if [ -d "$i" ]; then # if directory exists
         local result="$i" # result is the directory that exists
      fi
   done
   echo "$result" # "return" the directory that exists
}

firefox_dir=$(locate_firefox_dir)

get_default_profile() {
   profiles_ini="$firefox_dir/profiles.ini"
   if [ ! -f "$profiles_ini" ]; then
      exit
   fi

   # regex from https://askubuntu.com/a/354907
   # should also work on MacOS
   if [[ $(grep '\[Profile[0-9{2}]\]' "$profiles_ini") ]]; then
      profile_path=$(grep -E '\[Profile|^Path|^Default' "$profiles_ini" | grep -1 '^Default=1' | grep '^Path' | cut -c6-)
   else
      profile_path=$(grep 'Path=' "$profiles_ini" | sed 's/^Path=//')
   fi

   echo "$firefox_dir/$profile_path"
}

default_profile_path=$(get_default_profile)
