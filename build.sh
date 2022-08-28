#!/usr/bin/env bash

set -o errexit
set -o pipefail

for dep in "packwiz" "curl" "jq" "rg" "zip"; do
    if ! command -v "${dep}" >/dev/null 2>&1; then
        echo >&2 "Error: Missing dependency: ${dep}"
        exit 1
    fi
done

# build mrpack
packwiz refresh
packwiz modrinth export
zip --update --recurse-paths \
    "$(find -- * -type f -iname '*.mrpack' | head -n1)" \
    "overrides" "client-overrides" "server-overrides"

# fetch mod infos
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

# generate markdown list
echo "| Title | Description | License | Wiki | Source | Discord |" >MODS.md
echo "| --- | --- | --- | --- | --- | --- |" >>MODS.md
jq --raw-output \
    '.[] | [.title, .description, .license.name, .wiki_url, .source_url, .discord_url] | @tsv | sub("\t";" | ";"g")' \
    dependencies.json | sed 's/.*/| & |/' >>MODS.md
