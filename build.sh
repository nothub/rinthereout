#!/usr/bin/env bash
# https://packwiz.infra.link/installation

set -o errexit

rm -f ./*.mrpack

packwiz refresh
packwiz modrinth export

# TODO: build dependency list
# https://api.modrinth.com/v2/project/rinthereout/dependencies
