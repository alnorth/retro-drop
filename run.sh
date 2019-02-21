#!/bin/bash

# Proper sign up experience

# - Add config option to the retropie menu
# - Web interface for signing up
# - ncurses interface that can be used with a contoller for initial setup
# - Download config from website

# Packaging up for installation via RetroPie interface

# - How do the packages work?

. /opt/retropie/configs/retro-drop/config.ini

today=`date -u +%Y%m%d-%H%M`
zipfile_name="saved-games-${today}.tar.gz"

cd ${rom_directory}

# File patterns copied from https://retropie.org.uk/forum/topic/13108/script-to-backup-save-states-and-sram
tar --ignore-failed-read -cvzf - */*.srm* */*.bsv* */*.sav* */*.sta* */*.fs* */*.nv* */*.rtc* | \
  curl -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer ${dropbox_access_token}" \
    --header "Dropbox-API-Arg: {\"path\": \"/${retropi_name}/${zipfile_name}\",\"mode\": \"add\",\"autorename\": true,\"mute\": false,\"strict_conflict\": false}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @-

# List the current files in the folder so that we can see if we need to delete any.
# We use python to parse the JSON data. RetroPie is using 2.7 still.
to_delete=$(\
  curl -X POST https://api.dropboxapi.com/2/files/list_folder \
    --header "Authorization: Bearer ${dropbox_access_token}" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"/${retropi_name}/\",\"recursive\": false,\"include_media_info\": false,\"include_deleted\": false,\"include_has_explicit_shared_members\": false,\"include_mounted_folders\": true}" | \
  python -c "import sys, json; ns = [e['name'] for e in json.load(sys.stdin)['entries']]; print '\n'.join(ns[:-${copies_to_retain}])" \
)

for file in ${to_delete}; do
  curl -X POST https://api.dropboxapi.com/2/files/delete_v2 \
      --header "Authorization: Bearer ${dropbox_access_token}" \
      --header "Content-Type: application/json" \
      --data "{\"path\": \"/${retropi_name}/${file}\"}"
done
