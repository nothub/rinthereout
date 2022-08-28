#!/usr/bin/env bash

set -o errexit
set -o pipefail

check_dependency() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo >&2 "Error: Missing dependency: $1"
        exit 1
    fi
}

check_dependency packwiz
check_dependency curl
check_dependency jq
check_dependency rg
check_dependency zip

# build mrpack
packwiz refresh
packwiz modrinth export

# add override folders
mrpack=$(find -- * -type f -iname '*.mrpack' | head -n1)
zip --update --recurse-paths "${mrpack}" "overrides" "client-overrides" "server-overrides"

# generate mod list
mod_ids=()
for f in ./mods/*; do
    # shellcheck disable=SC2016
    mod_ids+=("%22$(rg 'mod-id = "([\d\w]{8})"' --only-matching --replace '$1' "${f}" | cat)%22")
done
curl --silent --location --get \
    --data "$(IFS=, ; echo "ids=[${mod_ids[*]}]")" \
    --header "Accept: application/json" \
    "https://api.modrinth.com/v2/projects" \
    | jq >dependencies.json
echo "| Title | Description | License | Wiki | Source | Discord |" >MODS.md
echo "| --- | --- | --- | --- | --- | --- |" >>MODS.md
jq --raw-output \
    '.[] | [.title, .description, .license.name, .wiki_url, .source_url, .discord_url] | @tsv | sub("\t";" | ";"g")' \
    dependencies.json | sed 's/.*/| & |/' >>MODS.md
