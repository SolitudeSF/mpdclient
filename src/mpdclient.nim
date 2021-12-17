import std/[strutils, times, strtabs, options, sequtils]
export options.get, options.isSome
export strtabs.`[]`, strtabs.`$`, strtabs.getOrDefault, strtabs.contains

# times.nim bug 9901
{.warning[ProveInit]: off.}

import ./mpdclient/[types, args, parse, client, filters]
export types, client, filters

# Querying MPD status

proc clearError*(mpd: MPDClient) =
  mpd.runCommandOk "clearerror"

proc currentSong*(mpd: MPDClient): Option[Song] =
  mpd.runCommand "currentsong"
  let song = mpd.getSong
  if song.place.isSome:
    result = some(song)

proc idle*(mpd: MPDClient, subsystem: string | SubsystemKind): SubsystemKind =
  mpd.runCommand "idle", subsystem.toArg
  mpd.getValue.parseSubsystem

proc idle*(mpd: MPDClient): SubsystemKind =
  mpd.runCommand "idle"
  mpd.getValue.parseSubsystem

proc status*(mpd: MPDClient): Status =
  mpd.runCommand "status"
  mpd.getStatus

proc stats*(mpd: MPDClient): Stats =
  mpd.runCommand "stats"
  mpd.getStats

# Playback options

proc consume*(mpd: MPDClient; val: bool) =
  mpd.runCommandOk "consume", val.toArg

proc repeat*(mpd: MPDClient; val: bool) =
  mpd.runCommandOk "repeat", val.toArg

proc random*(mpd: MPDClient; val: bool) =
  mpd.runCommandOk "random", val.toArg

proc single*(mpd: MPDClient; val: bool) =
  mpd.runCommandOk "single", val.toArg

proc setVol*(mpd: MPDClient; val: range[0..100]) =
  mpd.runCommandOk "setvol", val.toArg

proc getVol*(mpd: MPDClient): int8 =
  mpd.runCommand "getvol"
  mpd.getValue.parseInt.int8

template volume*(mpd, val) = mpd.setVol val

proc mixRampDb*(mpd: MPDClient; val: float32) =
  mpd.runCommandOk "mixrampdb", val.toArg

proc mixRampDelay*(mpd: MPDClient; val: float64) =
  mpd.runCommandOk "mixrampdelay", val.toArg

proc replayGainMode*(mpd: MPDClient; val: ReplayGainMode) =
  mpd.runCommandOk "replay_gain_mode", val.toArg

proc replayGainStatus*(mpd: MPDClient): ReplayGainMode =
  mpd.runCommand "replay_gain_status"
  mpd.getValue.parseReplayGainMode

# Controlling playback

proc next*(mpd: MPDClient) =
  mpd.runCommandOk "next"

proc previous*(mpd: MPDClient) =
  mpd.runCommandOk "previous"

proc stop*(mpd: MPDClient) =
  mpd.runCommandOk "stop"

proc togglePause*(mpd: MPDClient) =
  mpd.runCommandOk "pause"

proc pause*(mpd: MPDClient; val: bool) =
  mpd.runCommandOk "pause", val.toArg

proc play*(mpd: MPDClient) =
  mpd.runCommandOk "play"

proc play*(mpd: MPDClient; pos: uint32) =
  mpd.runCommandOk "play", pos.toArg

proc playId*(mpd: MPDClient; id: uint32) =
  mpd.runCommandOk "playid", id.toArg

proc seek*(mpd: MPDClient; pos: uint32, dur: Duration | float) =
  mpd.runCommandOk "seek", pos, dur.toArg

proc seekId*(mpd: MPDClient; id: uint32, dur: Duration | float) =
  mpd.runCommandOk "seekid", id, dur.toArg

proc seekCur*(mpd: MPDClient; dur: Duration | float) =
  mpd.runCommandOk "seekcur", dur.toArg

template seek*(mpd, dur) = mpd.seekCur dur

# The Queue

proc add*(mpd: MPDClient; uri: string) =
  mpd.runCommandOk "add", uri

proc addId*(mpd: MPDClient; uri: string): uint32 =
  mpd.runCommand "addid", uri
  mpd.getValue.parseUint32

proc addId*(mpd: MPDClient; uri: string, pos: uint32): uint32 =
  mpd.runCommand "addid", uri, pos.toArg
  mpd.getValue.parseUint32

proc clear*(mpd: MPDClient) =
  mpd.runCommandOk "clear"

proc delete*(mpd: MPDClient; range: uint32 | SongRange) =
  mpd.runCommandOk "delete", range.toArg

proc deleteId*(mpd: MPDClient; id: uint32) =
  mpd.runCommandOk "deleteid", id.toArg

proc move*(mpd: MPDClient; range: uint32 | SongRange, to: uint32) =
  mpd.runCommandOk "move", range.toArg, to.toArg

proc moveId*(mpd: MPDClient; id, to: uint32) =
  mpd.runCommandOk "moveid", id.toArg, to.toArg

proc playlistFind*(mpd: MPDClient, tag: Tag, needle: string): seq[Song] =
  if mpd.runCommandList("playlistfind", tag.toArg, needle):
    mpd.getStructList "file", getSong

iterator playlistFind*(mpd: MPDClient, tag: Tag, needle: string): Song =
  if mpd.runCommandList("playlistfind", tag.toArg, needle):
    mpd.iterateStructList "file", getSong

proc playlistId*(mpd: MPDClient): seq[Song] =
  mpd.runCommand "playlistid"
  mpd.getStructList "file", getSong

iterator playlistId*(mpd: MPDClient):Song =
  mpd.runCommand "playlistid"
  mpd.iterateStructList "file", getSong

proc playlistId*(mpd: MPDClient; id: uint32): Song =
  mpd.runCommand "playlistid", id.toArg
  mpd.getSong

proc playlistInfo*(mpd: MPDClient): seq[Song] =
  mpd.runCommand "playlistinfo"
  mpd.getStructList "file", getSong

iterator playlistInfo*(mpd: MPDClient): Song =
  mpd.runCommand "playlistinfo"
  mpd.iterateStructList "file", getSong

proc playlistInfo*(mpd: MPDClient; pos: uint32): Song =
  mpd.runCommand "playlistinfo", pos.toArg
  mpd.getSong

proc playlistInfo*(mpd: MPDClient; range: SongRange): seq[Song] =
  mpd.runCommand "playlistinfo", range.toArg
  mpd.getStructList "file", getSong

iterator playlistInfo*(mpd: MPDClient; range: SongRange): Song =
  mpd.runCommand "playlistinfo", range.toArg
  mpd.iterateStructList "file", getSong

proc playlistSearch*(mpd: MPDClient, tag: Tag, needle: string): seq[Song] =
  if mpd.runCommandList("playlistsearch", tag.toArg, needle):
    mpd.getStructList "file", getSong

iterator playlistSearch*(mpd: MPDClient, tag: Tag, needle: string): Song =
  if mpd.runCommandList("playlistsearch", tag.toArg, needle):
    mpd.iterateStructList "file", getSong

proc playlistChanges*(mpd: MPDClient, version: string, range: SongRange): seq[Song] =
  mpd.runCommand "plchanges", version, range.toArg
  mpd.getStructList "file", getSong

iterator playlistChanges*(mpd: MPDClient, version: string, range: SongRange): Song =
  mpd.runCommand "plchanges", version, range.toArg
  mpd.iterateStructList "file", getSong

proc playlistChanges*(mpd: MPDClient, version: string): seq[Song] =
  mpd.runCommand "plchanges", version
  mpd.getStructList "file", getSong

iterator playlistChanges*(mpd: MPDClient, version: string): Song =
  mpd.runCommand "plchanges", version
  mpd.iterateStructList "file", getSong

proc playlistChangesPosId*(mpd: MPDClient, version: string, range: SongRange): seq[PosId] =
  mpd.runCommand "plchangesposid", version, range.toArg
  mpd.getStructList "cpos", getPosId

iterator playlistChangesPosId*(mpd: MPDClient, version: string, range: SongRange): PosId =
  mpd.runCommand "plchangesposid", version, range.toArg
  mpd.iterateStructList "cpos", getPosId

proc playlistChangesPosId*(mpd: MPDClient, version: string): seq[PosId] =
  mpd.runCommand "plchangesposid", version
  mpd.getStructList "cpos", getPosId

iterator playlistChangesPosId*(mpd: MPDClient, version: string): PosId =
  mpd.runCommand "plchangesposid", version
  mpd.iterateStructList "cpos", getPosId

proc prio*(mpd: MPDClient, prio: uint8, range: uint32 | SongRange) =
  mpd.runCommandOk "prio", prio.toArg, range.toArg

proc prioId*(mpd: MPDClient, prio: uint8, id: uint32) =
  mpd.runCommandOk "prioid", prio.toArg, id.toArg

proc rangeIdRemove*(mpd: MPDClient, id: uint32) =
  mpd.runCommandOk "rangeid", id.toArg, ":"

proc rangeId*(mpd: MPDClient, id: uint32, range: TimeRange | HSlice[float, float]) =
  mpd.runCommandOk "rangeid", id.toArg, range.toArg

proc shuffle*(mpd: MPDClient, range: SongRange) =
  mpd.runCommandOk "shuffle", range.toArg

proc shuffle*(mpd: MPDClient) =
  mpd.runCommandOk "shuffle"

proc swap*(mpd: MPDClient, pos1, pos2: uint32) =
  mpd.runCommandOk "swap", pos1.toArg, pos2.toArg

proc swapId*(mpd: MPDClient, pos1, pos2: uint32) =
  mpd.runCommandOk "swapid", pos1.toArg, pos2.toArg

proc addTagId*(mpd: MPDClient, id: uint32, tag, value: string) =
  mpd.runCommandOk "addtagid", id.toArg, tag, value

proc cleartagid*(mpd: MPDClient, id: uint32, tag: string) =
  mpd.runCommandOk "cleartagid", id.toArg, tag

proc cleartagid*(mpd: MPDClient, id: uint32) =
  mpd.runCommandOk "cleartagid", id.toArg

# Stored playlists

proc listPlaylist*(mpd: MPDClient, name: string): seq[Song] =
  mpd.runCommand "listplaylist", name
  mpd.getStructList "file", getSong

iterator listPlaylist*(mpd: MPDClient, name: string): Song =
  mpd.runCommand "listplaylist", name
  mpd.iterateStructList "file", getSong

proc listPlaylistInfo*(mpd: MPDClient, name: string): seq[Song] =
  mpd.runCommand "listplaylistinfo", name
  mpd.getStructList "file", getSong

iterator listPlaylistInfo*(mpd: MPDClient, name: string): Song =
  mpd.runCommand "listplaylistinfo", name
  mpd.iterateStructList "file", getSong

proc listPlaylists*(mpd: MPDClient): seq[Playlist] =
  mpd.runCommand "listplaylists"
  mpd.getStructList "playlist", getPlaylist

iterator listPlaylists*(mpd: MPDClient): Playlist =
  mpd.runCommand "listplaylists"
  mpd.iterateStructList "playlist", getPlaylist

proc load*(mpd: MPDClient, playlist: string | Playlist, range: SongRange) =
  mpd.runCommandOk "load", playlist.toArg, range.toArg

proc load*(mpd: MPDClient, playlist: string | Playlist) =
  mpd.runCommandOk "load", playlist.toArg

proc playlistAdd*(mpd: MPDClient, playlist: string | Playlist, uri: string) =
  mpd.runCommandOk "playlistadd", playlist.toArg, uri

proc playlistClear*(mpd: MPDClient, playlist: string | Playlist) =
  mpd.runCommandOk "playlistclear", playlist.toArg

proc playlistDelete*(mpd: MPDClient, playlist: string | Playlist, pos: uint32) =
  mpd.runCommandOk "playlistdelete", playlist.toArg, pos.toArg

proc playlistMove*(mpd: MPDClient, playlist: string | Playlist, pos, to: uint32) =
  mpd.runCommandOk "playlistmove", playlist.toArg, pos.toArg, to.toArg

proc rename*(mpd: MPDClient, playlist: string | Playlist, to: string) =
  mpd.runCommandOk "rename", playlist.toArg, to

proc rm*(mpd: MPDClient, playlist: string | Playlist) =
  mpd.runCommandOk "rm", playlist.toArg

proc save*(mpd: MPDClient, playlist: string | Playlist) =
  mpd.runCommandOk "save", playlist.toArg

# The music database

proc albumart*(mpd: MPDClient, uri: string, offset = 0): tuple[size: uint32, data: seq[byte]] =
  mpd.runCommand "albumart", uri, offset.toArg
  result.size = mpd.getValue.parseUint32
  result.data = mpd.getBinary
  mpd.expectOk

proc count*(mpd: MPDClient, filter: Filter): tuple[songs, playtime: int] =
  mpd.runCommand "count", filter.toArg
  (mpd.getPair[1].parseInt, mpd.getPair[1].parseInt)

proc countGrouped*(mpd: MPDClient, filter: Filter, group: Tag): seq[CountGroup] =
  mpd.runCommand "count", filter.toArg, "group", group.toArg
  for (key, val) in mpd:
    case key:
    of "songs": result[^1].songs = val.parseInt
    of "playtime": result[^1].playtime = val.parseInt
    else: result.add CountGroup(tag: group, name: val)

iterator countGrouped*(mpd: MPDClient, filter: Filter, group: Tag): CountGroup =
  mpd.runCommand "count", filter.toArg, "group", group.toArg
  var res: CountGroup
  for (key, val) in mpd:
    case key:
    of "songs": res.songs = val.parseInt
    of "playtime": res.playtime = val.parseInt
    else:
      if res.songs > 0:
        yield res
      res = CountGroup(tag: group, name: val)
  yield res

proc getFingerprint*(mpd: MPDClient, uri: string): string =
  mpd.runCommand "getfingerprint", uri
  mpd.getValue

template findCompose(cmd: string, filter: Filter, sort: SortOrder): untyped =
  var args = @[filter.toArg]
  if sort.tag != tagAny:
    args.add "sort"
    args.add sort.toArg
  mpd.runCommand cmd, args

template findCompose(cmd: string, filter: Filter, sort: SortOrder, window: SongRange): untyped =
  var args = @[filter.toArg]
  if sort.tag != tagAny:
    args.add "sort"
    args.add sort.toArg
  args.add "window"
  args.add window.toArg
  mpd.runCommand cmd, args

proc findAdd*(mpd: MPDClient, filter: Filter, sort = noSort) =
  ## Requires MPD >= 0.22
  findCompose "findadd", filter, sort
  mpd.expectOk

proc findAdd*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange) =
  ## Requires MPD >= 0.22
  findCompose "findadd", filter, sort, window
  mpd.expectOk

proc searchAdd*(mpd: MPDClient, filter: Filter, sort = noSort) =
  ## Requires MPD >= 0.22
  findCompose "searchadd", filter, sort
  mpd.expectOk

proc searchAdd*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange) =
  ## Requires MPD >= 0.22
  findCompose "searchadd", filter, sort, window
  mpd.expectOk

proc searchAddPl*(mpd: MPDClient, name: string, filter: Filter, sort = noSort) =
  ## Requires MPD >= 0.22
  var args = @[name, filter.toArg]
  if sort.tag != tagAny:
    args.add "sort"
    args.add sort.toArg
  mpd.runCommandOk "searchaddpl", args

proc searchAddPl*(mpd: MPDClient, name: string, filter: Filter, sort = noSort, window: SongRange) =
  ## Requires MPD >= 0.22
  var args = @[name, filter.toArg]
  if sort.tag != tagAny:
    args.add "sort"
    args.add sort.toArg
  args.add "window"
  args.add window.toArg
  mpd.runCommandOk "searchaddpl", args

proc findAdd*(mpd: MPDClient, filter: Filter) =
  ## Requires MPD >= 0.21
  mpd.runCommandOk "findadd", filter.toArg

proc searchAdd*(mpd: MPDClient, filter: Filter) =
  ## Requires MPD >= 0.21
  mpd.runCommandOk "searchadd", filter.toArg

proc searchAddPl*(mpd: MPDClient, name: string, filter: Filter) =
  ## Requires MPD >= 0.21
  mpd.runCommandOk "searchaddpl", name, filter.toArg

proc find*(mpd: MPDClient, filter: Filter, sort = noSort): seq[Song] =
  ## Requires MPD >= 0.21
  findCompose "find", filter, sort
  mpd.getStructList "file", getSong

iterator find*(mpd: MPDClient, filter: Filter, sort = noSort): Song =
  ## Requires MPD >= 0.21
  findCompose "find", filter, sort
  mpd.iterateStructList "file", getSong

proc find*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange): seq[Song] =
  ## Requires MPD >= 0.21
  findCompose "find", filter, sort, window
  mpd.getStructList "file", getSong

iterator find*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange): Song =
  ## Requires MPD >= 0.21
  findCompose "find", filter, sort, window
  mpd.iterateStructList "file", getSong

proc search*(mpd: MPDClient, filter: Filter, sort = noSort): seq[Song] =
  ## Requires MPD >= 0.21
  findCompose "search", filter, sort
  mpd.getStructList "file", getSong

iterator search*(mpd: MPDClient, filter: Filter, sort = noSort): Song =
  ## Requires MPD >= 0.21
  findCompose "search", filter, sort
  mpd.iterateStructList "file", getSong

proc search*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange): seq[Song] =
  ## Requires MPD >= 0.21
  findCompose "search", filter, sort, window
  mpd.getStructList "file", getSong

iterator search*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange): Song =
  ## Requires MPD >= 0.21
  findCompose "search", filter, sort, window
  mpd.iterateStructList "file", getSong

proc list*(mpd: MPDClient, tag: Tag, filter: Filter): seq[string] =
  ## Requires MPD >= 0.21
  mpd.runCommand "list", tag.toArg, filter.toArg
  mpd.getValues

iterator list*(mpd: MPDClient, tag: Tag, filter: Filter): string =
  ## Requires MPD >= 0.21
  mpd.runCommand "list", tag.toArg, filter.toArg
  mpd.iterateValues

proc listGrouped*(mpd: MPDClient, tag: Tag, filter: Filter, group: Tag): seq[(string, seq[string])] =
  ## Requires MPD >= 0.21
  mpd.runCommand "list", tag.toArg, filter.toArg, "group", group.toArg
  for (key, val) in mpd:
    if key == $group:
      result.add (val, @[])
    else:
      result[^1][1].add val

iterator listGrouped*(mpd: MPDClient, tag: Tag, filter: Filter, group: Tag): (string, seq[string]) =
  ## Requires MPD >= 0.21
  mpd.runCommand "list", tag.toArg, filter.toArg, "group", group.toArg
  var res: (string, seq[string])
  for (key, val) in mpd:
    if key == $group:
      if res[1].len > 0:
        yield res
      res = (val, @[])
    else:
      res[1].add val
  yield res

proc listAll*(mpd: MPDClient, uri: string): seq[(InfoEntryKind, string)] =
  ## Do not use this
  mpd.runCommand "listall", uri
  for (key, val) in mpd:
    case key:
    of "directory": result.add (entryDirectory, val)
    of "file": result.add (entryFile, val)
    of "playlist": result.add (entryPlaylist, val)
    else: discard

iterator listAll*(mpd: MPDClient, uri: string): (InfoEntryKind, string) =
  ## Do not use this
  mpd.runCommand "listall", uri
  for (key, val) in mpd:
    case key:
    of "directory": yield (entryDirectory, val)
    of "file": yield (entryFile, val)
    of "playlist": yield (entryPlaylist, val)
    else: discard

template infoRoutine(mpd: MPDClient): untyped =
  for (key, val) in mpd:
    case key:
    of "directory":
      result.add InfoEntry(kind: entryDirectory, name: val, tags: newStringTable())
    of "file":
      result.add InfoEntry(kind: entryFile, name: val, tags: newStringTable())
    of "playlist":
      result.add InfoEntry(kind: entryPlaylist, name: val, tags: newStringTable())
    else: result[^1].tags[key] = val

template infoIterRoutine(mpd: MPDClient): untyped =
  var res: InfoEntry
  for (key, val) in mpd:
    case key:
    of "directory":
      if res.name.len > 0: yield res
      res.kind = entryDirectory
      res.name = val
      res.tags = newStringTable()
    of "file":
      if res.name.len > 0: yield res
      res.kind = entryFile
      res.name = val
      res.tags = newStringTable()
    of "Playlist":
      if res.name.len > 0: yield res
      res.kind = entryPlaylist
      res.name = val
      res.tags = newStringTable()
    else:
      res.tags[key] = val
  yield res

proc listFiles*(mpd: MPDClient, uri: string): seq[InfoEntry] =
  mpd.runCommand "listfiles", uri
  mpd.infoRoutine

iterator listFiles*(mpd: MPDClient, uri: string): InfoEntry =
  mpd.runCommand "listfiles", uri
  mpd.infoIterRoutine

proc listInfo*(mpd: MPDClient, uri: string): seq[InfoEntry] =
  mpd.runCommand "lsinfo", uri
  mpd.infoRoutine

iterator listInfo*(mpd: MPDClient, uri: string): InfoEntry =
  mpd.runCommand "lsinfo", uri
  mpd.infoIterRoutine

proc readComments*(mpd: MPDClient, uri: string): seq[(string, string)] =
  mpd.runCommand "readcomments", uri
  for pair in mpd: result.add pair

iterator readComments*(mpd: MPDClient, uri: string): (string, string) =
  mpd.runCommand "readcomments", uri
  for pair in mpd: yield pair

proc readPicture*(mpd: MPDClient, offset = 0):
    tuple[size: uint32, mimetype: string, data: seq[byte]] =
  ## Requires MPD >= 0.22
  mpd.runCommand "readpicture", offset.toArg
  result.size = mpd.getValue.parseUint32
  result.mimetype = mpd.getValue
  result.data = mpd.getBinary
  mpd.expectOk

proc update*(mpd: MPDClient): uint32 =
  mpd.runCommand "update"
  mpd.getValue.parseUint32

proc update*(mpd: MPDClient, uri: string): uint32 =
  mpd.runCommand "update", uri
  mpd.getValue.parseUint32

proc rescan*(mpd: MPDClient): uint32 =
  mpd.runCommand "rescan"
  mpd.getValue.parseUint32

proc rescan*(mpd: MPDClient, uri: string): uint32 =
  mpd.runCommand "rescan", uri
  mpd.getValue.parseUint32


# Mounts and neighbors

proc mount*(mpd: MPDClient, path, uri: string) =
  mpd.runCommandOk "mount", path, uri

proc unmount*(mpd: MPDClient, path: string) =
  mpd.runCommandOk "unmount", path

proc listMounts*(mpd: MPDClient): seq[Mount] =
  mpd.runCommand "listmounts"
  mpd.getStructList "mount", getMount

iterator listMounts*(mpd: MPDClient): Mount =
  mpd.runCommand "listmounts"
  mpd.iterateStructList "mount", getMount

proc listNeighbors*(mpd: MPDClient): seq[Neighbor] =
  mpd.runCommand "listneighbors"
  mpd.getStructList "neighbor", getMount

iterator listNeighbors*(mpd: MPDClient): Neighbor =
  mpd.runCommand "listneighbors"
  mpd.iterateStructList "neighbor", getMount

# Stickers

proc stickerGet*(mpd: MPDClient, uri, name: string): Sticker =
  mpd.runCommand "sticker get song", uri, name
  mpd.getSticker

proc stickerSet*(mpd: MPDClient, uri, name, value: string) =
  mpd.runCommandOk "sticker set song", uri, name, value

proc stickerDelete*(mpd: MPDClient, uri, name: string) =
  mpd.runCommandOk "sticker delete song", uri, name

proc stickerDeleteAll*(mpd: MPDClient, uri: string) =
  mpd.runCommandOk "sticker delete song", uri

proc stickerList*(mpd: MPDClient, uri: string): seq[Sticker] =
  mpd.runCommand "sticker list song", uri
  mpd.getStructList "sticker", getSticker

iterator stickerList*(mpd: MPDClient, uri: string): Sticker =
  mpd.runCommand "sticker list song", uri
  mpd.iterateStructList "sticker", getSticker

proc stickerFind*(mpd: MPDClient, uri, name: string): seq[FileSticker] =
  mpd.runCommand "sticker find song", uri, name
  mpd.getStructList "file", getFileSticker

iterator stickerFind*(mpd: MPDClient, uri, name: string): FileSticker =
  mpd.runCommand "sticker find song", uri, name
  mpd.iterateStructList "file", getFileSticker

proc stickerFindWithValue*(mpd: MPDClient, uri, name, value: string, operator = stOpEquals): seq[FileSticker] =
  mpd.runCommand "sticker find song", uri, name, operator.toArg, value
  mpd.getStructList "file", getFileSticker

iterator stickerFindWithValue*(mpd: MPDClient, uri, name, value: string, operator = stOpEquals): FileSticker =
  mpd.runCommand "sticker find song", uri, name, operator.toArg, value
  mpd.iterateStructList "file", getFileSticker

# Connection settings

proc ping*(mpd: MPDClient) =
  mpd.runCommandOk "ping"

proc password*(mpd: MPDClient, password: string) =
  mpd.runCommandOk "password", password

proc tagtypes*(mpd: MPDClient): seq[string] =
  mpd.runCommand "tagtypes"
  mpd.getValues

iterator tagtypes*(mpd: MPDClient): string =
  mpd.runCommand "tagtypes"
  mpd.iterateValues

proc tagtypesDisable*(mpd: MPDClient, tags: varargs[Tag]) =
  mpd.runCommandOk "tagtypes disable", tags.mapIt(it.toArg)

proc tagtypesEnable*(mpd: MPDClient, tags: varargs[Tag]) =
  mpd.runCommandOk "tagtypes enable", tags.mapIt(it.toArg)

proc tagtypesClear*(mpd: MPDClient) =
  mpd.runCommandOk "tagtypes clear"

proc tagtypesAll*(mpd: MPDClient) =
  mpd.runCommandOk "tagtypes all"

# Partition commands

proc partition*(mpd: MPDClient, part: string | Partition) =
  mpd.runCommandOk "partition", part.toArg

proc listPartitions*(mpd: MPDClient): seq[Partition] =
  mpd.runCommand "listpartitions"
  mpd.getStructList "partition", getPartition

iterator listPartitions*(mpd: MPDClient): Partition =
  mpd.runCommand "listpartitions"
  mpd.iterateStructList "partition", getPartition

proc newPartition*(mpd: MPDClient, name: string) =
  mpd.runCommandOk "newpartition", name

proc delPartition*(mpd: MPDClient, name: string) =
  ## Requires MPD >= 0.22
  mpd.runCommandOk "delpartition", name

proc moveOutput*(mpd: MPDClient, name: string) =
  ## Requires MPD >= 0.22
  mpd.runCommandOk "moveoutput", name

# Audio output devices

proc disableOutput*(mpd: MPDClient, output: uint32 | Output) =
  mpd.runCommand "disableoutput", output.toArg

proc enableOutput*(mpd: MPDClient, output: uint32 | Output) =
  mpd.runCommand "enableoutput", output.toArg

proc toggleOutput*(mpd: MPDClient, output: uint32 | Output) =
  mpd.runCommand "toggleoutput", output.toArg

proc outputs*(mpd: MPDClient): seq[Output] =
  mpd.runCommand "outputs"
  mpd.getStructList "outputid", getOutput

iterator outputs*(mpd: MPDClient): Output =
  mpd.runCommand "outputs"
  mpd.iterateStructList "outputid", getOutput

proc outputSet*(mpd: MPDClient, output: uint32 | Output, name, value: string) =
  mpd.runCommandOk "outputset", output.toArg, name, value

template outputSwitch*(mpd: MPDClient, output: uint32, state: bool) =
  if state:
    mpd.enableOutput output
  else:
    mpd.disableOutput output

template switch*(mpd: MPDClient, output: Output, state: bool) =
  if state:
    mpd.enableOutput output
  else:
    mpd.disableOutput output

# Reflection

proc config*(mpd: MPDClient): Config =
  mpd.runCommand "config"
  mpd.getConfig

proc commands*(mpd: MPDClient): seq[string] =
  mpd.runCommand "commands"
  mpd.getValues

iterator commands*(mpd: MPDClient): string =
  mpd.runCommand "commands"
  mpd.iterateValues

proc notCommands*(mpd: MPDClient): seq[string] =
  mpd.runCommand "notcommands"
  mpd.getValues

iterator notCommands*(mpd: MPDClient): string =
  mpd.runCommand "notcommands"
  mpd.iterateValues

proc urlHandlers*(mpd: MPDClient): seq[string] =
  mpd.runCommand "urlhandlers"
  mpd.getValues

iterator urlHandlers*(mpd: MPDClient): string =
  mpd.runCommand "urlhandlers"
  mpd.iterateValues

proc decoders*(mpd: MPDClient): seq[Decoder] =
  mpd.runCommand "decoders"
  mpd.getStructList "plugin", getDecoder

iterator decoders*(mpd: MPDClient): Decoder =
  mpd.runCommand "decoders"
  mpd.iterateStructList "plugin", getDecoder

# Client to client

proc subscribe*(mpd: MPDClient; channel: string) =
  mpd.runCommandOk "subscribe", channel

proc unsubscribe*(mpd: MPDClient; channel: string) =
  mpd.runCommandOk "unsubscribe", channel

proc channels*(mpd: MPDClient): seq[string] =
  mpd.runCommand "channels"
  mpd.getValues

iterator channels*(mpd: MPDClient): string =
  mpd.runCommand "channels"
  mpd.iterateValues

proc readMessages*(mpd: MPDClient): seq[Message] =
  mpd.runCommand "readmessages"
  mpd.getStructList "channel", getMessage

iterator readMessages*(mpd: MPDClient): Message =
  mpd.runCommand "readmessages"
  mpd.iterateStructList "channel", getMessage

proc sendMessage*(mpd: MPDClient, channel, message: string) =
  mpd.runCommandOk "sendmessage", channel, message
