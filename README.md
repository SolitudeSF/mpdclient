# MPD client library

MPD client library for [Nim](https://nim-lang.org)

## Installation

`nimble install mpdclient`

## Example usage

```nim
import mpdclient

let mpd = newMPDClient()
for song in mpd.playlistId:
  echo song.tags["Album"]
```
