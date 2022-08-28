#!/usr/bin/env bash

set -o errexit
set -o pipefail

project_slug="rinthereout"
mc_version="1.18.2"
jvm_memory="4G"

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
        #jq --raw-output --arg mc_version "$mc_version" '.[] | select( .version_type == "release" ) | select( .game_versions[] | contains($mc_version))' |
        jq --raw-output --arg mc_version "$mc_version" '.[] | select( .game_versions[] | contains($mc_version))' |
        jq --raw-output '.files[] | select( .primary == true )' | jq --slurp '.[0]')
    if [[ ${latest_json} == "null" ]]; then
        echo >&2 "No stable ${project_slug} ${mc_version} release found!"
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
    loader_ver=$(curl --silent --location --header "Accept: application/json" \
        "https://meta.fabricmc.net/v2/versions/loader/${mc_version}" |
        jq --raw-output '.[0].loader.version')
    installer_ver=$(curl --silent --location --header "Accept: application/json" \
        "https://meta.fabricmc.net/v2/versions/installer" |
        jq --raw-output '.[0].version')
    curl --location --progress-bar --remote-time --output "fabric-server.jar" \
        "https://meta.fabricmc.net/v2/versions/loader/${mc_version}/${loader_ver}/${installer_ver}/server/jar"
fi

# eula
if [[ ${MC_EULA} == "true" ]]; then
    echo "eula=true" >"eula.txt"
else
    echo >&2 "Set MC_EULA=true to agree with Mojangs EULA: https://account.mojang.com/documents/minecraft_eula"
fi

# run server
java -Xms${jvm_memory} -Xmx${jvm_memory} -jar fabric-server.jar nogui
