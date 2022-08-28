#!/usr/bin/env bash

set -o errexit
set -o pipefail

packwiz refresh

rm -f ./*.mrpack
packwiz modrinth export

# TODO: include the overrides normally when packwiz introduces environment side support for internal files
zip --update --recurse-paths \
    "$(find -- * -maxdepth 0 -type f -iname '*.mrpack' | head -n1)" \
    "overrides" "client-overrides" "server-overrides"
