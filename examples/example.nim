# based on https://raw.githubusercontent.com/cmende/libmpdclient/master/src/example.c

import mpdclient
import times

let mpd = newMPDClient()

let status = mpd.status
echo "volume: ", status.volume
echo "repeat: ", status.repeat
echo "queue version: ", status.queueVersion
echo "queue length: ", status.queueLen

if status.error.isSome:
  echo "error: ", status.error.get

if status.state in {statePlay, statePause}:
  if status.song.isSome:
    echo "song: ", status.song.get.pos
  echo "elaspedTime: ", status.elapsed.inSeconds
  echo "elasped_ms: ", status.elapsed.inMilliseconds
  echo "totalTime: ", status.duration.inSeconds
  echo "bitRate: ", status.bitrate

let audioFormat = status.audio
echo "sampleRate: ", audioFormat.rate
echo "bits: ", audioFormat.bits
echo "channels: ", audioFormat.channels

let song = mpd.currentSong
if song.isSome:
  let song = song.get
  echo "uri: ", song.file
  echo "artist: ", song.artist
  echo "album: ", song.tags[$tagAlbum]
  echo "title: ", song.title
  echo "track: ", song.tags[$tagTrack]
  echo "name: ", song.name
  echo "date: ", song.tags[$tagDate]

  echo "time: ", song.duration.inSeconds
  echo "pos: ", song.place.get.pos

for playlist in mpd.listPlaylists:
  echo "playlist: ", playlist.name

