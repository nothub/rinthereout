#!/usr/bin/env bash

set -o errexit
set -o pipefail

slug="rinthereout"

# TODO: download fabric server
# curl -OJ https://meta.fabricmc.net/v2/versions/loader/1.18.2/0.14.9/0.11.1/server/jar
# java -Xmx2G -jar fabric-server-mc.1.18.2-loader.0.14.9-launcher.0.11.1.jar nogui

# TODO: download https://github.com/packwiz/packwiz-installer
# java -jar packwiz-installer-bootstrap.jar -g -s server https://[your-server]/pack.toml

# TODO: download latest mrpack distribution
json="$(curl --silent --location --header "Accept: application/json" "https://api.modrinth.com/v2/project/${slug}/version")"
# project_id="$(echo "${json}" | jq --raw-output --compact-output '. sort_by(.date_published)')"
# echo "https://api.modrinth.com/v2/project/${slug}/version"

# TODO: install overrides from mrpack archive
