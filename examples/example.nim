import mpdclient
from times import inMilliseconds

let
  mpd = newMPDClient()
  status = mpd.status

echo "volume: ", status.volume
echo "repeat: ", status.repeat
echo "queueVersion: ", status.queueVersion
echo "queueLen: ", status.queueLen

if status.error.isSome:
  echo "error: ", status.error.get

if status.state in {statePlay, statePause}:
  echo "song: ", status.song
  echo "elaspedTime: ",status.elapsed
  echo "elasped_ms: ", status.elapsed.inMilliseconds
  echo "totalTime: ", status.duration
  echo "bitRate: ", status.audio.bits

let audioFormat = status.audio

echo "sampleRate: ", audioFormat.rate
echo "bits: ", audioFormat.bits
echo "channels: ", audioFormat.channels


let song = mpd.currentSong

if song.isSome:
  let song = song.get
  echo "file: ", song.file
  echo "artist: ", song.artist
  echo "title: ", song.title
  echo "name: ", song.name
  echo "album: ", song.tags[$tagAlbum]
  echo "date: ", song.tags[$tagDate]

  echo "time: ", song.duration
  echo "pos: ", song.place.get.pos

for playlist in mpd.listPlaylists:
  echo "playlist: ", playlist.name

