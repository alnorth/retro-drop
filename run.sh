#!/bin/bash

# Simple script

# - Generate zip file
# - Upload zip file to Dropbox
# - Get zip pattern right (copy an existing backup script)
# - Read INI from the right path
# - Only retain a certain number of zip files
# - Make sure it copes gracefully with failed web requests
# - Test out on RetroPie

# Proper sign up experience

# - Add config option to the retropie menu
# - Web interface for signing up
# - ncurses interface that can be used with a contoller for initial setup
# - Download config from website

# Packaging up for installation via RetroPie interface

# - How do the packages work?

. /opt/retropie/configs/retro-drop/config.ini

today=`date +%Y%m%d-%H%M`
zipfile_name="saved-games-${today}.tar.gz"

cd ${rom_directory}
tar -cvzf - */*.srm* | \
  curl -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer ${dropbox_access_token}" \
    --header "Dropbox-API-Arg: {\"path\": \"/${retropi_name}/${zipfile_name}\",\"mode\": \"add\",\"autorename\": true,\"mute\": false,\"strict_conflict\": false}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @-

