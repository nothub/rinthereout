#!/usr/bin/env bash

set -o errexit
set -o pipefail

project_slug="rinthereout"
server_dir="${project_slug}-server"
jvm_memory="4G"

for dep in "curl" "java" "jq"; do
    if ! command -v "${dep}" >/dev/null 2>&1; then
        echo >&2 "Missing dependency: ${dep}"
        exit 1
    fi
done

# download mrpack installer
if [[ ! -f mrpack-install ]]; then
    release_assets=$(curl --silent --location https://api.github.com/repos/nothub/mrpack-install/releases/latest)
    url=$(echo "${release_assets}" | jq --compact-output --raw-output \
        '.assets[] | select(.name == "mrpack-install-linux") | .browser_download_url')
    curl --location --progress-bar --remote-time --output "mrpack-install" "${url}"
    chmod +x mrpack-install
fi

# deploy modpack server
if [[ $# -gt 0 ]] && [[ -f ${1} ]]; then
    ./mrpack-install "${1}" --server-dir ${server_dir} --server-file fabric-server.jar
else
    ./mrpack-install ${project_slug} --server-dir ${server_dir} --server-file fabric-server.jar
fi

# handle eula
if [[ ${MC_EULA} == "true" ]]; then
    echo "eula=true" >"${server_dir}/eula.txt"
else
    echo >&2 "Set MC_EULA=true to agree with Mojangs EULA: https://account.mojang.com/documents/minecraft_eula"
fi

# run server
(cd ${server_dir} && java -Xms${jvm_memory} -Xmx${jvm_memory} -jar fabric-server.jar nogui)
