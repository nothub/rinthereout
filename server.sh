#!/usr/bin/env bash

set -o errexit
set -o pipefail

project_slug="rinthereout"
minecraft_version="1.18.2"

jvm_memory="2G"

fabric_loader_version="0.14.9"
fabric_installer_version="0.11.1"

for dep in "curl" "java" "jq" "unzip" "sha512sum" "inline-detox"; do
    if ! command -v "${dep}" >/dev/null 2>&1; then
        echo >&2 "Missing dependency: ${dep}"
        exit 1
    fi
done

mrpack="$(find -- * -maxdepth 0 -type f -iname "${project_slug}-*.mrpack" | head -n1)"
if [[ -z ${mrpack} ]]; then
    # find latest stable
    latest_json=$(curl --silent --location --header "Accept: application/json" "https://api.modrinth.com/v2/project/${project_slug}/version" |
        #jq --raw-output --arg minecraft_version "$minecraft_version" '.[] | select( .version_type == "release" ) | select( .game_versions[] | contains($minecraft_version))' |
        jq --raw-output --arg minecraft_version "$minecraft_version" '.[] | select( .game_versions[] | contains($minecraft_version))' |
        jq --raw-output '.files[] | select( .primary == true )' | jq --slurp '.[0]')
    if [[ ${latest_json} == "null" ]]; then
        echo >&2 "No stable ${project_slug} ${minecraft_version} release found!"
        exit 1
    fi
    # download mrpack
    mrpack=$(echo "${latest_json}" | jq --raw-output '.filename' | inline-detox)
    curl --location --progress-bar --remote-time --output "${mrpack}" "$(echo "${latest_json}" | jq --raw-output '.url')"
    echo "$(echo "${latest_json}" | jq --raw-output '.hashes.sha512')  ${mrpack}" | sha512sum -c -
fi

if [[ ! -d "mrpack" ]]; then
    unzip "${mrpack}" -d "mrpack"
    tree -a -n "mrpack"
fi

# download mods
mkdir -p mods
for mod in $(jq --compact-output --raw-output '.files[] | select( .env.server != "unsupported" ) | @base64' "./mrpack/modrinth.index.json"); do
    json=$(echo "${mod}" | base64 --decode | jq --compact-output --raw-output)
    path=$(echo "${json}" | jq --raw-output '.path')
    if [[ ! -f ${path} ]]; then
        curl --location --progress-bar --remote-time --output "${path}" "$(echo "${json}" | jq --raw-output '.downloads[0]')"
        echo "$(echo "${json}" | jq --raw-output '.hashes.sha512')  ${path}" | sha512sum -c -
    fi
done

# install overrides
for override in "./mrpack/overrides" "./mrpack/server-overrides"; do
    if [[ -d "${override}" ]]; then cp --verbose --no-clobber --recursive "${override}"/* "."; fi
done

# download fabric server
if [[ ! -f "fabric-server.jar" ]]; then
    curl --location --progress-bar --remote-time --output "fabric-server.jar" \
        "https://meta.fabricmc.net/v2/versions/loader/${minecraft_version}/${fabric_loader_version}/${fabric_installer_version}/server/jar"
fi

# run server
java -Xmx${jvm_memory} -jar fabric-server.jar nogui
