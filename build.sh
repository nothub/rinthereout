#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

rm -f ./*.mrpack

pack_name="$(rg 'name = "(.*)"' --only-matching --replace '$1' "pack.toml" | cat)"
pack_version="$(rg 'version = "(.*)"' --only-matching --replace '$1' "pack.toml" | cat)"
echo >&2 "Creating mrpack archive for: ${pack_name} ${pack_version}"

echo >&2 "Updating motd..."
sed -i "s/^motd=.*$/motd=${pack_name} ${pack_version}/" server-overrides/server.properties

packwiz modrinth export

# TODO: include the overrides normally when packwiz introduces environment side support for internal files
echo >&2 "Adding overrides..."
zip --update --recurse-paths \
    "$(find -- * -maxdepth 0 -type f -iname '*.mrpack' | head -n1)" \
    "overrides" "client-overrides" "server-overrides"

echo >&2 "done :)"
