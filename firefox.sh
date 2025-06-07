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
   # check if the profiles_ini file exists
   if [ ! -f "$profiles_ini" ]; then
      exit
   fi

   # regex from https://askubuntu.com/a/354907
   # should also work on MacOS
   if [[ $(grep '\[Profile[^0]\]' "$profiles_ini") ]]; then
      # First select the three lines containing "Profile, Path, Default"
      #
      # grep -1 adds one extra line of context AROUND the match (in this case 
      # the line before Default=1 contains Path and the line after is EMPTY)
      #
      # then single out the line containing ^Path.
      #
      # The line containing Path is 'Path=...' where ... is the name of the 
      # directory containing the profile.
      # `cut -c6-` selects the text from the 6th character to the end of the 
      # string, the 6th character is the first character of the folder name
      profile_path=$(grep -E '\[Profile|^Path|^Default' "$profiles_ini" | grep -1 '^Default=1' | grep '^Path' | cut -c6-)
   else
      # if there is only one profile then a simple grep for Path will work
      # this sed command removes 'Path=' and leaves the profile directory name
      profile_path=$(grep 'Path=' "$profiles_ini" | sed 's/^Path=//')
   fi

   echo "$firefox_dir/$profile_path"
}

default_profile_path=$(get_default_profile)
addons_json_path="$default_profile_path/addons.json"

extract_addons() {
   # check if addons.json exists
   if [ ! -f "$addons_json_path" ]; then
      exit
   fi

   # search for all json k+v pairs with a key containing "name" or "version"
   # in the "addons.json" file. By searching until the separating comma after a 
   # match
   all_name_and_version_keys=$(grep -Po '"name":.*?[^\\]",|"version":.*?[^\\]",' ~/snap/firefox/common/.mozilla/firefox/n412qyv8.default/addons.json)
   # this returns the names of the addons, alongside the version. Consequentually,
   # this also returns the names of the authors. To remediate this, grep can 
   # provide negative context to a match (x lines before the match). Since 
   # the version is between the name of the addon and the names of the authors,
   # we can grep a second time for version k+v pairs and provide the previous line
   # (the name of the addon) as additional context.
   addonName_addonVer=$(echo "$all_name_and_version_keys" | grep -P -B 1 '"version":.*?[^\\]",')

   echo "$addonName_addonVer"
}

unformatted_addons=$(extract_addons)

format_addons_as_json() {
   rm_ver_trailing_comma=$(echo "$unformatted_addons" | sed -E 's/("version":.*["])(,)/\1/')

   dash_replace=$(echo "$rm_ver_trailing_comma" | sed -E "s/--/},\n{/")

   fmt_addons=$(echo "$dash_replace" | sed -E 's/(^\")/      \1/' | sed -E 's/(^[{}])/    \1/' | sed -E 's/(:)/\1 /')

   make_valid_json_and_fmt=$(printf "%b%b%b" '{\n  "addons:": [\n    {\n' "$fmt_addons" '\n    }\n  ]\n}')

   echo $make_valid_json_and_fmt
}

echo $(format_addons_as_json)
