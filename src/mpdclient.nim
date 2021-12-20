import std/[strutils, times, strtabs, options]
export options.get, options.isSome
export strtabs.`[]`, strtabs.`$`, strtabs.getOrDefault, strtabs.contains

# times.nim bug 9901
{.warning[ProveInit]: off.}

import ./mpdclient/[types, args, parse, client, filters]
export types, filters
export newMPDClient

template iterateStructList(mpd: MPDClient; firstKey: string, t: typedesc): untyped =
  for struct in mpd.structs(firstKey, t):
    yield struct

template iterateValues(mpd: MPDClient): untyped =
  for value in mpd.values:
    yield value

template toSeq(t: iterable): untyped =
  for i in t:
    result.add i

# Querying MPD status

proc clearError*(mpd: MPDClient) =
  mpd.runCommandOk "clearerror"

proc currentSong*(mpd: MPDClient): Option[Song] =
  mpd.runCommand "currentsong"
  let song = mpd.get Song
  if song.place.isSome:
    result = some(song)

proc idle*(mpd: MPDClient, subsystem: string | SubsystemKind): SubsystemKind =
  mpd.runCommand "idle", subsystem
  mpd.getValue.parseSubsystem

proc idle*(mpd: MPDClient): SubsystemKind =
  mpd.runCommand "idle"
  mpd.getValue.parseSubsystem

proc status*(mpd: MPDClient): Status =
  mpd.runCommand "status"
  mpd.get result

proc stats*(mpd: MPDClient): Stats =
  mpd.runCommand "stats"
  mpd.get result

# Playback options

proc consume*(mpd: MPDClient; val: bool) =
  mpd.runCommandOk "consume", val

proc repeat*(mpd: MPDClient; val: bool) =
  mpd.runCommandOk "repeat", val

proc random*(mpd: MPDClient; val: bool) =
  mpd.runCommandOk "random", val

proc single*(mpd: MPDClient; val: bool) =
  mpd.runCommandOk "single", val

proc setVol*(mpd: MPDClient; val: range[0..100]) =
  mpd.runCommandOk "setvol", val

proc getVol*(mpd: MPDClient): int8 =
  mpd.runCommand "getvol"
  mpd.getValue.parseInt.int8

proc mixRampDb*(mpd: MPDClient; val: float32) =
  mpd.runCommandOk "mixrampdb", val

proc mixRampDelay*(mpd: MPDClient; val: float64) =
  mpd.runCommandOk "mixrampdelay", val

proc replayGainMode*(mpd: MPDClient; val: ReplayGainMode) =
  mpd.runCommandOk "replay_gain_mode", val

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
  mpd.runCommandOk "pause", val

proc play*(mpd: MPDClient) =
  mpd.runCommandOk "play"

proc play*(mpd: MPDClient; pos: uint32) =
  mpd.runCommandOk "play", pos

proc playId*(mpd: MPDClient; id: uint32) =
  mpd.runCommandOk "playid", id

proc seek*(mpd: MPDClient; pos: uint32, dur: Duration | float) =
  mpd.runCommandOk "seek", pos, dur

proc seekId*(mpd: MPDClient; id: uint32, dur: Duration | float) =
  mpd.runCommandOk "seekid", id, dur

proc seekCur*(mpd: MPDClient; dur: Duration | float) =
  mpd.runCommandOk "seekcur", dur

# The Queue

proc add*(mpd: MPDClient; uri: string) =
  mpd.runCommandOk "add", uri

proc add*(mpd: MPDClient; uri: string, pos: int | Relative) =
  mpd.runCommandOk "add", uri, pos

proc addId*(mpd: MPDClient; uri: string): uint32 =
  mpd.runCommand "addid", uri
  mpd.getValue.parseUint32

proc addId*(mpd: MPDClient; uri: string, pos: uint32 | Relative): uint32 =
  mpd.runCommand "addid", uri, pos
  mpd.getValue.parseUint32

proc clear*(mpd: MPDClient) =
  mpd.runCommandOk "clear"

proc delete*(mpd: MPDClient; range: uint32 | SongRange) =
  mpd.runCommandOk "delete", range

proc deleteId*(mpd: MPDClient; id: uint32) =
  mpd.runCommandOk "deleteid", id

proc move*(mpd: MPDClient; range: uint32 | SongRange, to: uint32) =
  mpd.runCommandOk "move", range, to

proc moveId*(mpd: MPDClient; id, to: uint32) =
  mpd.runCommandOk "moveid", id, to

iterator playlistFind*(mpd: MPDClient, tag: Tag, needle: string): Song =
  if mpd.runCommandList("playlistfind", tag, needle):
    mpd.iterateStructList "file", Song

proc playlistFind*(mpd: MPDClient, tag: Tag, needle: string): seq[Song] =
  toSeq mpd.playlistFind(tag, needle)

iterator playlistId*(mpd: MPDClient):Song =
  mpd.runCommand "playlistid"
  mpd.iterateStructList "file", Song

proc playlistId*(mpd: MPDClient): seq[Song] =
  toSeq mpd.playlistId

proc playlistId*(mpd: MPDClient; id: uint32): Song =
  mpd.runCommand "playlistid", id
  mpd.get result

iterator playlistInfo*(mpd: MPDClient): Song =
  mpd.runCommand "playlistinfo"
  mpd.iterateStructList "file", Song

proc playlistInfo*(mpd: MPDClient): seq[Song] =
  toSeq mpd.playlistInfo

proc playlistInfo*(mpd: MPDClient; pos: uint32): Song =
  mpd.runCommand "playlistinfo", pos
  mpd.get result

iterator playlistInfo*(mpd: MPDClient; range: SongRange): Song =
  mpd.runCommand "playlistinfo", range
  mpd.iterateStructList "file", Song

proc playlistInfo*(mpd: MPDClient; range: SongRange): seq[Song] =
  toSeq mpd.playlistInfo range

iterator playlistSearch*(mpd: MPDClient, tag: Tag, needle: string): Song =
  if mpd.runCommandList("playlistsearch", tag, needle):
    mpd.iterateStructList "file", Song

proc playlistSearch*(mpd: MPDClient, tag: Tag, needle: string): seq[Song] =
  toSeq mpd.playlistSearch(tag, needle)

iterator playlistChanges*(mpd: MPDClient, version: string, range: SongRange): Song =
  mpd.runCommand "plchanges", version, range
  mpd.iterateStructList "file", Song

proc playlistChanges*(mpd: MPDClient, version: string, range: SongRange): seq[Song] =
  toSeq mpd.playlistChanges(version, range)

iterator playlistChanges*(mpd: MPDClient, version: string): Song =
  mpd.runCommand "plchanges", version
  mpd.iterateStructList "file", Song

proc playlistChanges*(mpd: MPDClient, version: string): seq[Song] =
  toSeq mpd.playlistChanges version

iterator playlistChangesPosId*(mpd: MPDClient, version: string, range: SongRange): PosId =
  mpd.runCommand "plchangesposid", version, range
  mpd.iterateStructList "cpos", PosId

proc playlistChangesPosId*(mpd: MPDClient, version: string, range: SongRange): seq[PosId] =
  toSeq mpd.playlistChangesPosId(version, range)

iterator playlistChangesPosId*(mpd: MPDClient, version: string): PosId =
  mpd.runCommand "plchangesposid", version
  mpd.iterateStructList "cpos", PosId

proc playlistChangesPosId*(mpd: MPDClient, version: string): seq[PosId] =
  toSeq mpd.playlistChangesPosId version

proc prio*(mpd: MPDClient, prio: uint8, range: uint32 | SongRange) =
  mpd.runCommandOk "prio", prio, range

proc prioId*(mpd: MPDClient, prio: uint8, id: uint32) =
  mpd.runCommandOk "prioid", prio, id

proc rangeIdRemove*(mpd: MPDClient, id: uint32) =
  mpd.runCommandOk "rangeid", id, ":"

proc rangeId*(mpd: MPDClient, id: uint32, range: TimeRange | HSlice[float, float]) =
  mpd.runCommandOk "rangeid", id, range

proc shuffle*(mpd: MPDClient, range: SongRange) =
  mpd.runCommandOk "shuffle", range

proc shuffle*(mpd: MPDClient) =
  mpd.runCommandOk "shuffle"

proc swap*(mpd: MPDClient, pos1, pos2: uint32) =
  mpd.runCommandOk "swap", pos1, pos2

proc swapId*(mpd: MPDClient, pos1, pos2: uint32) =
  mpd.runCommandOk "swapid", pos1, pos2

proc addTagId*(mpd: MPDClient, id: uint32, tag, value: string) =
  mpd.runCommandOk "addtagid", id, tag, value

proc cleartagid*(mpd: MPDClient, id: uint32, tag: string) =
  mpd.runCommandOk "cleartagid", id, tag

proc cleartagid*(mpd: MPDClient, id: uint32) =
  mpd.runCommandOk "cleartagid", id

# Stored playlists

iterator listPlaylist*(mpd: MPDClient, name: string): Song =
  mpd.runCommand "listplaylist", name
  mpd.iterateStructList "file", Song

proc listPlaylist*(mpd: MPDClient, name: string): seq[Song] =
  toSeq mpd.listPlaylist name

iterator listPlaylistInfo*(mpd: MPDClient, name: string): Song =
  mpd.runCommand "listplaylistinfo", name
  mpd.iterateStructList "file", Song

proc listPlaylistInfo*(mpd: MPDClient, name: string): seq[Song] =
  toSeq mpd.listPlaylistInfo name

iterator listPlaylists*(mpd: MPDClient): Playlist =
  mpd.runCommand "listplaylists"
  mpd.iterateStructList "playlist", Playlist

proc listPlaylists*(mpd: MPDClient): seq[Playlist] =
  toSeq mpd.listPlaylists

proc load*(mpd: MPDClient, playlist: string | Playlist, range: SongRange) =
  mpd.runCommandOk "load", playlist, range

proc load*(mpd: MPDClient, playlist: string | Playlist) =
  mpd.runCommandOk "load", playlist

proc playlistAdd*(mpd: MPDClient, playlist: string | Playlist, uri: string) =
  mpd.runCommandOk "playlistadd", playlist, uri

proc playlistAdd*(mpd: MPDClient, playlist: string | Playlist, uri: string, pos: uint32) =
  mpd.runCommandOk "playlistadd", playlist, uri, pos

proc playlistClear*(mpd: MPDClient, playlist: string | Playlist) =
  mpd.runCommandOk "playlistclear", playlist

proc playlistDelete*(mpd: MPDClient, playlist: string | Playlist, pos: uint32 | SongRange) =
  mpd.runCommandOk "playlistdelete", playlist, pos

proc playlistMove*(mpd: MPDClient, playlist: string | Playlist, pos, to: uint32) =
  mpd.runCommandOk "playlistmove", playlist, pos, to

proc rename*(mpd: MPDClient, playlist: string | Playlist, to: string) =
  mpd.runCommandOk "rename", playlist, to

proc rm*(mpd: MPDClient, playlist: string | Playlist) =
  mpd.runCommandOk "rm", playlist

proc save*(mpd: MPDClient, playlist: string | Playlist) =
  mpd.runCommandOk "save", playlist

# The music database

proc albumart*(mpd: MPDClient, uri: string, offset = 0): tuple[size: uint32, data: seq[byte]] =
  mpd.runCommand "albumart", uri, offset
  result.size = mpd.getValue.parseUint32
  result.data = mpd.getBinary
  mpd.expectOk

proc count*(mpd: MPDClient, filter: Filter): tuple[songs, playtime: int] =
  mpd.runCommand "count", filter
  (mpd.getPair[1].parseInt, mpd.getPair[1].parseInt)

proc countGrouped*(mpd: MPDClient, filter: Filter, group: Tag): seq[CountGroup] =
  mpd.runCommand "count", filter, "group", group
  for (key, val) in mpd:
    case key:
    of "songs": result[^1].songs = val.parseInt
    of "playtime": result[^1].playtime = val.parseInt
    else: result.add CountGroup(tag: group, name: val)

iterator countGrouped*(mpd: MPDClient, filter: Filter, group: Tag): CountGroup =
  mpd.runCommand "count", filter, "group", group
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
  var payload = cmd
  payload.add ' '
  payload.addArg filter
  if sort.tag != tagAny:
    payload.add " sort "
    payload.addArg sort
  mpd.send payload

template findCompose(cmd: string, filter: Filter, sort: SortOrder, window: SongRange): untyped =
  var payload = cmd
  payload.add ' '
  payload.addArg filter
  if sort.tag != tagAny:
    payload.add " sort "
    payload.addArg sort
  payload.add " window "
  payload.addArg window
  mpd.send payload

template findCompose(cmd: string, filter: Filter, sort: SortOrder, window: Option[SongRange],
  pos): untyped =
  var payload = cmd
  payload.add ' '
  payload.addArg filter
  if sort.tag != tagAny:
    payload.add " sort "
    payload.addArg sort
  if window.isSome:
    payload.add " window "
    payload.addArg get window
  if pos.isSome:
    payload.add " position "
    payload.addArg pos.get
  mpd.send payload

proc findAdd*(mpd: MPDClient, filter: Filter, sort = noSort) =
  ## Requires MPD >= 0.22
  findCompose "findadd", filter, sort
  mpd.expectOk

proc findAdd*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange) =
  ## Requires MPD >= 0.22
  findCompose "findadd", filter, sort, window
  mpd.expectOk

proc findAdd*[T: uint32 or Relative](mpd: MPDClient, filter: Filter, sort = noSort, window = none SongRange,
  pos = none T) =
  findCompose "findadd", filter, sort, window, pos
  mpd.expectOk

proc searchAdd*(mpd: MPDClient, filter: Filter) =
  ## Requires MPD >= 0.21
  mpd.runCommandOk "searchadd", filter

proc searchAdd*(mpd: MPDClient, filter: Filter, sort = noSort) =
  ## Requires MPD >= 0.22
  findCompose "searchadd", filter, sort
  mpd.expectOk

proc searchAdd*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange) =
  ## Requires MPD >= 0.22
  findCompose "searchadd", filter, sort, window
  mpd.expectOk

proc searchAdd*[T: uint32 or Relative](mpd: MPDClient, filter: Filter, sort = noSort, window = none SongRange,
  pos = none T) =
  findCompose "searchadd", filter, sort, window, pos
  mpd.expectOk

proc searchAddPl*(mpd: MPDClient, name: string, filter: Filter) =
  ## Requires MPD >= 0.21
  mpd.runCommandOk "searchaddpl", name, filter

proc searchAddPl*(mpd: MPDClient, name: string, filter: Filter, sort = noSort) =
  ## Requires MPD >= 0.22
  var cmd = "searchaddpl "
  cmd.add name
  cmd.add ' '
  cmd.addArg filter
  if sort.tag != tagAny:
    cmd.add " sort "
    cmd.addArg sort
  mpd.send cmd
  mpd.expectOk

proc searchAddPl*(mpd: MPDClient, name: string, filter: Filter, sort = noSort, window: SongRange) =
  ## Requires MPD >= 0.22
  var cmd = "searchaddpl "
  cmd.add name
  cmd.add ' '
  cmd.addArg filter
  if sort.tag != tagAny:
    cmd.add " sort "
    cmd.addArg sort
  cmd.add " window "
  cmd.addArg window
  mpd.send cmd
  mpd.expectOk

proc findAdd*(mpd: MPDClient, filter: Filter) =
  ## Requires MPD >= 0.21
  mpd.runCommandOk "findadd", filter

iterator find*(mpd: MPDClient, filter: Filter, sort = noSort): Song =
  ## Requires MPD >= 0.21
  findCompose "find", filter, sort
  mpd.iterateStructList "file", Song

proc find*(mpd: MPDClient, filter: Filter, sort = noSort): seq[Song] =
  ## Requires MPD >= 0.21
  toSeq mpd.find(filter, sort)

iterator find*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange): Song =
  ## Requires MPD >= 0.21
  findCompose "find", filter, sort, window
  mpd.iterateStructList "file", Song

proc find*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange): seq[Song] =
  ## Requires MPD >= 0.21
  toSeq mpd.find(filter, sort, window)

iterator search*(mpd: MPDClient, filter: Filter, sort = noSort): Song =
  ## Requires MPD >= 0.21
  findCompose "search", filter, sort
  mpd.iterateStructList "file", Song

proc search*(mpd: MPDClient, filter: Filter, sort = noSort): seq[Song] =
  ## Requires MPD >= 0.21
  toSeq mpd.search(filter, sort)

iterator search*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange): Song =
  ## Requires MPD >= 0.21
  findCompose "search", filter, sort, window
  mpd.iterateStructList "file", Song

proc search*(mpd: MPDClient, filter: Filter, sort = noSort, window: SongRange): seq[Song] =
  ## Requires MPD >= 0.21
  toSeq mpd.search(filter, sort, window)

iterator list*(mpd: MPDClient, tag: Tag, filter: Filter): string =
  ## Requires MPD >= 0.21
  mpd.runCommand "list", tag, filter
  mpd.iterateValues

proc list*(mpd: MPDClient, tag: Tag, filter: Filter): seq[string] =
  ## Requires MPD >= 0.21
  toSeq mpd.list(tag, filter)

proc listGrouped*(mpd: MPDClient, tag: Tag, filter: Filter, group: Tag): seq[(string, seq[string])] =
  ## Requires MPD >= 0.21
  mpd.runCommand "list", tag, filter, "group", group
  for (key, val) in mpd:
    if key == $group:
      result.add (val, @[])
    else:
      result[^1][1].add val

iterator listGrouped*(mpd: MPDClient, tag: Tag, filter: Filter, group: Tag): (string, seq[string]) =
  ## Requires MPD >= 0.21
  mpd.runCommand "list", tag, filter, "group", group
  var res: (string, seq[string])
  for (key, val) in mpd:
    if key == $group:
      if res[1].len > 0:
        yield res
      res = (val, @[])
    else:
      res[1].add val
  yield res

iterator listAll*(mpd: MPDClient, uri: string): (InfoEntryKind, string) =
  ## Do not use this
  mpd.runCommand "listall", uri
  for (key, val) in mpd:
    case key:
    of "directory": yield (entryDirectory, val)
    of "file": yield (entryFile, val)
    of "playlist": yield (entryPlaylist, val)
    else: discard

proc listAll*(mpd: MPDClient, uri: string): seq[(InfoEntryKind, string)] =
  ## Do not use this
  toSeq mpd.listAll uri

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

iterator readComments*(mpd: MPDClient, uri: string): (string, string) =
  mpd.runCommand "readcomments", uri
  for pair in mpd: yield pair

proc readComments*(mpd: MPDClient, uri: string): seq[(string, string)] =
  toSeq mpd.readComments uri

proc readPicture*(mpd: MPDClient, offset = 0):
    tuple[size: uint32, mimetype: string, data: seq[byte]] =
  ## Requires MPD >= 0.22
  mpd.runCommand "readpicture", offset
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

iterator listMounts*(mpd: MPDClient): Mount =
  mpd.runCommand "listmounts"
  mpd.iterateStructList "mount", Mount

proc listMounts*(mpd: MPDClient): seq[Mount] =
  toSeq mpd.listMounts

iterator listNeighbors*(mpd: MPDClient): Neighbor =
  mpd.runCommand "listneighbors"
  mpd.iterateStructList "neighbor", Mount

proc listNeighbors*(mpd: MPDClient): seq[Neighbor] =
  toSeq mpd.listNeighbors

# Stickers

proc stickerGet*(mpd: MPDClient, uri, name: string): Sticker =
  mpd.runCommand "sticker get song", uri, name
  mpd.get result

proc stickerSet*(mpd: MPDClient, uri, name, value: string) =
  mpd.runCommandOk "sticker set song", uri, name, value

proc stickerDelete*(mpd: MPDClient, uri, name: string) =
  mpd.runCommandOk "sticker delete song", uri, name

proc stickerDeleteAll*(mpd: MPDClient, uri: string) =
  mpd.runCommandOk "sticker delete song", uri

iterator stickerList*(mpd: MPDClient, uri: string): Sticker =
  mpd.runCommand "sticker list song", uri
  mpd.iterateStructList "sticker", Sticker

proc stickerList*(mpd: MPDClient, uri: string): seq[Sticker] =
  toSeq mpd.stickerList uri

iterator stickerFind*(mpd: MPDClient, uri, name: string): FileSticker =
  mpd.runCommand "sticker find song", uri, name
  mpd.iterateStructList "file", FileSticker

proc stickerFind*(mpd: MPDClient, uri, name: string): seq[FileSticker] =
  toSeq mpd.stickerFind(uri, name)

iterator stickerFindWithValue*(mpd: MPDClient, uri, name, value: string, operator = stOpEquals): FileSticker =
  mpd.runCommand "sticker find song", uri, name, operator, value
  mpd.iterateStructList "file", FileSticker

proc stickerFindWithValue*(mpd: MPDClient, uri, name, value: string, operator = stOpEquals): seq[FileSticker] =
  toSeq mpd.stickerFindWithValue(uri, name, value, operator)

# Connection settings

proc ping*(mpd: MPDClient) =
  mpd.runCommandOk "ping"

proc password*(mpd: MPDClient, password: string) =
  mpd.runCommandOk "password", password

iterator tagtypes*(mpd: MPDClient): string =
  mpd.runCommand "tagtypes"
  mpd.iterateValues

proc tagtypes*(mpd: MPDClient): seq[string] =
  toSeq mpd.tagtypes

proc tagtypesDisable*(mpd: MPDClient, tags: varargs[Tag]) =
  var cmd = "tagtypes disable"
  for tag in tags:
    cmd.add ' '
    cmd.addArg tag
  mpd.send cmd
  mpd.expectOk

proc tagtypesEnable*(mpd: MPDClient, tags: varargs[Tag]) =
  var cmd = "tagtypes enable"
  for tag in tags:
    cmd.add ' '
    cmd.addArg tag
  mpd.send cmd
  mpd.expectOk

proc tagtypesClear*(mpd: MPDClient) =
  mpd.runCommandOk "tagtypes clear"

proc tagtypesAll*(mpd: MPDClient) =
  mpd.runCommandOk "tagtypes all"

# Partition commands

proc partition*(mpd: MPDClient, part: string | Partition) =
  mpd.runCommandOk "partition", part

iterator listPartitions*(mpd: MPDClient): Partition =
  mpd.runCommand "listpartitions"
  mpd.iterateStructList "partition", Partition

proc listPartitions*(mpd: MPDClient): seq[Partition] =
  toSeq mpd.listPartitions

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
  mpd.runCommand "disableoutput", output

proc enableOutput*(mpd: MPDClient, output: uint32 | Output) =
  mpd.runCommand "enableoutput", output

proc toggleOutput*(mpd: MPDClient, output: uint32 | Output) =
  mpd.runCommand "toggleoutput", output

iterator outputs*(mpd: MPDClient): Output =
  mpd.runCommand "outputs"
  mpd.iterateStructList "outputid", Output

proc outputs*(mpd: MPDClient): seq[Output] =
  toSeq mpd.outputs

proc outputSet*(mpd: MPDClient, output: uint32 | Output, name, value: string) =
  mpd.runCommandOk "outputset", output, name, value

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
  mpd.get result

iterator commands*(mpd: MPDClient): string =
  mpd.runCommand "commands"
  mpd.iterateValues

proc commands*(mpd: MPDClient): seq[string] =
  toSeq mpd.commands

iterator notCommands*(mpd: MPDClient): string =
  mpd.runCommand "notcommands"
  mpd.iterateValues

proc notCommands*(mpd: MPDClient): seq[string] =
  toSeq mpd.notCommands

iterator urlHandlers*(mpd: MPDClient): string =
  mpd.runCommand "urlhandlers"
  mpd.iterateValues

proc urlHandlers*(mpd: MPDClient): seq[string] =
  toSeq mpd.urlHandlers

iterator decoders*(mpd: MPDClient): Decoder =
  mpd.runCommand "decoders"
  mpd.iterateStructList "plugin", Decoder

proc decoders*(mpd: MPDClient): seq[Decoder] =
  toSeq mpd.decoders

# Client to client

proc subscribe*(mpd: MPDClient; channel: string) =
  mpd.runCommandOk "subscribe", channel

proc unsubscribe*(mpd: MPDClient; channel: string) =
  mpd.runCommandOk "unsubscribe", channel

iterator channels*(mpd: MPDClient): string =
  mpd.runCommand "channels"
  mpd.iterateValues

proc channels*(mpd: MPDClient): seq[string] =
  toSeq mpd.channels

iterator readMessages*(mpd: MPDClient): Message =
  mpd.runCommand "readmessages"
  mpd.iterateStructList "channel", Message

proc readMessages*(mpd: MPDClient): seq[Message] =
  toSeq mpd.readMessages

proc sendMessage*(mpd: MPDClient, channel, message: string) =
  mpd.runCommandOk "sendmessage", channel, message
