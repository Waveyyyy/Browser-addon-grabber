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

