#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

import requests

mod_id_pattern = re.compile('mod-id = "([a-zA-Z0-9]{8})"')


def main():
    mod_ids = list()

    for file in Path('mods').glob('*.pw.toml'):
        match = mod_id_pattern.search(file.read_text())
        if match is None or len(match.groups()) < 1:
            print('no mod-id in', file)
            sys.exit(1)
        mod_ids.append(match.group(1))

    for mod_id in mod_ids:
        response = requests.get('https://api.modrinth.com/v2/project/' + mod_id + '/version')
        versions = json.loads(response.text)
        has_update = False
        for version in versions:
            if version['version_type'] != 'release':
                continue
            for mc_version in version['game_versions']:
                if mc_version == '1.19.2':
                    has_update = True
                    break
        if not has_update:
            response = requests.get('https://api.modrinth.com/v2/project/' + mod_id)
            project = json.loads(response.text)
            print('No update yet for:', project['title'], '(' + project['slug'] + ')')


if __name__ == '__main__':
    main()
