#!/usr/bin/env python2.7

# TODO: Error handling for upload.

import ConfigParser, json, subprocess, time, urllib, urllib2

config = ConfigParser.ConfigParser({
  'rom_directory': '/home/pi/RetroPie/roms/',
  'copies_to_retain': '30'
})
config.read(['./config.ini', '/opt/retropie/configs/retro-drop/config.ini'])


def upload():
  today = time.strftime("%Y%m%d-%H%M")

  # We do the zip file building in bash so that we can easily stream it straight to the server.
  # File patterns copied from https://retropie.org.uk/forum/topic/13108/script-to-backup-save-states-and-sram
  upload_command_template = """\
  tar --ignore-failed-read -cvzf - */*.srm* */*.bsv* */*.sav* */*.sta* */*.fs* */*.nv* */*.rtc* | \
    curl -X POST https://content.dropboxapi.com/2/files/upload \
      --header "Authorization: Bearer {dropbox_access_token}" \
      --header "Dropbox-API-Arg: {{\\"path\\": \\"/{retropi_name}/saved-games-{today}.tar.gz\\",\\"mode\\": \\"add\\",\\"autorename\\": true,\\"mute\\": false,\\"strict_conflict\\": false}}" \
      --header "Content-Type: application/octet-stream\" \
      --data-binary @-
  """

  upload_command = upload_command_template.format(
    dropbox_access_token=config.get('DEFAULT', 'dropbox_access_token'),
    retropi_name=config.get('DEFAULT', 'retropi_name'),
    today=today
  )

  process = subprocess.Popen(
    upload_command,
    shell=True,
    stdout=subprocess.PIPE,
    cwd=config.get('DEFAULT', 'rom_directory')
  )
  output, error = process.communicate()

def dropbox_post(url, data):
  request = urllib2.Request(
    url,
    json.dumps(data),
    {
      'Authorization': 'Bearer {dropbox_access_token}'.format(
        dropbox_access_token=config.get('DEFAULT', 'dropbox_access_token')
      ),
      'Content-Type': 'application/json'
    }
  )    
  try:
    connection = urllib2.urlopen(request)
    return json.loads(connection.read())
  except urllib2.HTTPError,e:
    print e.read()
    return {}

def get_existing_files():
  response = dropbox_post(
    "https://api.dropboxapi.com/2/files/list_folder",
    { 'path': '/' + config.get('DEFAULT', 'retropi_name') }
  )
  return [e['name'] for e in response['entries']]

def delete_file(filename):
  print 'Deleting ' + filename 
  dropbox_post(
    "https://api.dropboxapi.com/2/files/delete_v2",
    { 'path': '/' + config.get('DEFAULT', 'retropi_name') + '/' + filename }
  )

upload()
existing_files = get_existing_files()
to_delete = existing_files[:-config.getint('DEFAULT', 'copies_to_retain')]

for filename in to_delete:
  delete_file(filename)