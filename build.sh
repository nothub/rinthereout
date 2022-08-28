#!/usr/bin/env bash

set -o errexit
set -o pipefail

log() {
    echo >&2 "$*"
}

check_dependency() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log "Error: Missing dependency: $1"
        exit 1
    fi
}

check_dependency packwiz
check_dependency curl
check_dependency jq
check_dependency rg

# build mrpack
packwiz refresh
packwiz modrinth export

# add override folders
mrpack=$(find -- * -type f -iname '*.mrpack' | head -n1)
# TODO

# generate mod list
mod_ids=()
for f in ./mods/*; do
    # shellcheck disable=SC2016
    mod_ids+=("%22$(rg 'mod-id = "([\d\w]{8})"' --only-matching --replace '$1' "${f}" | cat)%22")
done
id_param=$(IFS=, ; echo "ids=[${mod_ids[*]}]")
curl --silent --location --get --data "${id_param}" --header "Accept: application/json" "https://api.modrinth.com/v2/projects" | jq >dependencies.json
