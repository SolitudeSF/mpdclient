import os, net, times, options, strtabs
import strutils except parseBool
from posix import Stat, stat, S_ISSOCK
import ./parse, ./types

type
  MPDClient* = ref object
    host: string
    port: Port
    password: string
    socket: Socket

  ReplyKind = enum
    replyOk, replyAck, replyPair

  Reply = object
    case kind: ReplyKind
    of replyOk: discard
    of replyAck: ack: string
    of replyPair: key, value: string

  Pair = tuple[key, value: string]

func parseReply(s: string): Reply =
  if s == "OK" or s == "list_OK":
    Reply(kind: replyOk)
  elif s.startsWith "ACK ":
    Reply(kind: replyAck, ack: s[4..^1])
  else:
    let idx = s.find ':'
    Reply(kind: replyPair, key: s[0..<idx], value: s[idx + 1..^1].strip)

template readLine(mpd: MPDClient): string =
  mpd.socket.recvLine

proc connect(mpd: var MPDClient) =
  if mpd.host.startsWith '/':
    mpd.socket = newSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP)
    mpd.socket.connectUnix mpd.host
  else:
    mpd.socket = newSocket()
    mpd.socket.connect mpd.host, mpd.port

  if not mpd.readLine.startsWith "OK MPD ":
    raise newException(CatchableError, "Error while connecting")

proc existsSocket(s: string): bool =
  var res: Stat
  return stat(s, res) >= 0 and S_ISSOCK(res.st_mode)

proc newMPDClient*(): MPDClient =
  result = MPDClient(host: "127.0.0.1")
  result.port = block:
    let port = getEnv "MPD_PORT"
    if port.len > 0:
      port.parseInt.Port
    else:
      6600.Port

  let hostEnv = getEnv "MPD_HOST"
  if hostEnv.len > 0:
    let parts = hostEnv.split '@'
    if parts.len > 1:
      result.host = parts[0]
      result.password = parts[1]
    else:
      result.host = parts[0]
  else:
    let
      xdgRuntimeDir = getEnv("XDG_RUNTIME_DIR", "/run")
      socket = xdgRuntimeDir / "mpd" / "socket"
    if existsSocket socket:
      result.host = socket

  result.connect

proc newMPDClient*(host: string, port = 6600'u16, password = ""): MPDClient =
  result = MPDClient(host: host, port: port.Port, password: password)
  result.connect

proc expectOk*(mpd: MPDClient) {.inline.} =
  let reply = mpd.readLine.parseReply
  if reply.kind == replyAck:
    raise newException(CatchableError, reply.ack)

proc expectList(mpd: MPDClient): bool {.inline.} =
  let reply = mpd.readLine.parseReply
  if reply.kind == replyAck:
    raise newException(CatchableError, reply.ack)
  reply.kind == replyPair

proc runCommand*(mpd: MPDClient; cmd: string, args: varargs[string]) =
  var command = cmd
  for arg in args:
    command &= " "
    command &= arg.escape
  mpd.socket.send command & "\x0a"

proc runCommandOk*(mpd: MPDClient; cmd: string, args: varargs[string]) {.inline.} =
  mpd.runCommand(cmd, args)
  mpd.expectOk

proc runCommandList*(mpd: MPDClient; cmd: string, args: varargs[string]): bool {.inline.} =
  mpd.runCommand(cmd, args)
  mpd.expectList

proc getPair*(mpd: MPDClient): Pair =
  let reply = mpd.readLine.parseReply
  case reply.kind
  of replyPair:
    result = (reply.key, reply.value)
  of replyOk:
    return
  of replyAck:
    raise newException(CatchableError, reply.ack)

proc getValue*(mpd: MPDClient): string =
  result = mpd.getPair.value
  mpd.expectOk

proc getBinary*(mpd: MPDClient): seq[byte] =
  let pair = mpd.getPair
  assert pair.key == "binary"
  let size = pair.value.parseUint32.int
  result.newSeq size
  let read = mpd.socket.recv(addr result[0], size)
  assert read == size

iterator items*(mpd: MPDClient): Pair =
  var line = ""
  while true:
    mpd.socket.readLine(line)
    let reply = line.parseReply
    case reply.kind
    of replyPair:
      yield (reply.key, reply.value)
    of replyOk:
      break
    of replyAck:
      raise newException(CatchableError, reply.ack)

template iterateStructList*(mpd: MPDClient; s: string, p): untyped =
  var pairs: seq[Pair]
  for pair in mpd:
    if pairs.len > 0 and pair.key == s:
      yield p(pairs)
      reset pairs
    pairs.add pair
  yield p(pairs)

template getStructList*(mpd: MPDClient; s: string, p): untyped =
  var pairs: seq[Pair]
  for pair in mpd:
    if pairs.len > 0 and pair.key == s:
      result.add p(pairs)
      reset pairs
    pairs.add pair
  result.add p(pairs)

proc getValues*(mpd: MPDClient): seq[string] =
  for (_, val) in mpd:
    result.add val

template iterateValues*(mpd: MPDClient): untyped =
  for pair in mpd:
    yield pair.value

proc getStatus*(mpd: MPDClient): Status =
  for (key, value) in mpd:
    case key
    of "partition":
      result.partition = value
    of "volume":
      result.volume = value.parseInt.int8
    of "repeat":
      result.repeat = value.parseBool
    of "random":
      result.random = value.parseBool
    of "consume":
      result.consume = value.parseBool
    of "single":
      result.single = value.parseBool
    of "mixrampdb":
      result.mixrampdb = value.parseFloat
    of "mixrampdelay":
      result.mixrampdelay = initDuration(seconds = value.parseInt)
    of "bitrate":
      result.bitrate = value.parseUint32
    of "state":
      result.state = value.parseState
    of "elapsed":
      result.elapsed = value.parseFloatSeconds
    of "duration":
      result.duration = value.parseFloatSeconds
    of "time":
      result.time = value.parseTime
    of "audio":
      result.audio = value.parseAudioFormat
    of "playlist":
      result.queueVersion = value.parseUint32
    of "playlistlength":
      result.queueLen = value.parseUint32
    of "song":
      if result.song.isSome:
        result.song.get.pos = value.parseUint32
      else:
        result.song = some(QueuePlace(pos: value.parseUint32))
    of "songid":
      if result.song.isSome:
        result.song.get.id = value.parseUint32
      else:
        result.song = some(QueuePlace(id: value.parseUint32))
    of "nextsong":
      if result.nextSong.isSome:
        result.nextSong.get.pos = value.parseUint32
      else:
        result.nextSong = some(QueuePlace(pos: value.parseUint32))
    of "nextsongid":
      if result.nextSong.isSome:
        result.nextSong.get.id = value.parseUint32
      else:
        result.nextSong = some(QueuePlace(id: value.parseUint32))
    of "updating_db":
      result.updatingDb = value.parseUint32.some
    of "error":
      result.error = value.some
    of "xfade":
      result.crossfade = initDuration(seconds = value.parseInt)
    else:
      raise newException(CatchableError, "Unknown struct key: " & key)

proc getStats*(mpd: MPDClient): Stats =
  for (key, value) in mpd:
    case key
    of "artists":
      result.artists = value.parseUint32
    of "albums":
      result.albums = value.parseUint32
    of "songs":
      result.songs = value.parseUint32
    of "uptime":
      result.uptime = initDuration(seconds = value.parseInt)
    of "playtime":
      result.playtime = initDuration(seconds = value.parseInt)
    of "db_playtime":
      result.dbPlaytime = initDuration(seconds = value.parseInt)
    of "db_update":
      result.dbUpdate = value.parseInt.fromUnix
    else:
      raise newException(CatchableError, "Unknown struct key: " & key)

proc getSong*(source: MPDClient | seq[Pair]): Song =
  result.tags = newStringTable()
  for (key, value) in source:
    case key
    of "file":
      result.file = value
    of "Title":
      result.title = value
    of "Last-Modified":
      result.lastModification = value.parse("yyyy-MM-dd'T'HH:mm:ss'Z'")
    of "Artist":
      result.artists.add value
    of "Name":
      result.name = value
    of "Time":
      result.duration = initDuration(seconds = value.parseInt)
    of "duration":
      result.duration = initDuration(milliseconds = int(value.parseFloat * 1000))
    of "Format":
      result.audio = value.parseAudioFormat
    of "Range":
      result.range = value.parseTimeRange
    of "Id":
      if result.place.isSome:
        result.place.get.id = value.parseUint32
      else:
        result.place = some(QueuePlace(id: value.parseUint32))
    of "Pos":
      if result.place.isSome:
        result.place.get.pos = value.parseUint32
      else:
        result.place = some(QueuePlace(pos: value.parseUint32))
    of "Prio":
      if result.place.isSome:
        result.place.get.priority = value.parseInt.uint8
      else:
        result.place = some(QueuePlace(priority: value.parseInt.uint8))
    else:
      result.tags[key] = value

proc getPlaylist*(source: MPDClient | seq[Pair]): Playlist =
  for (key, value) in source:
    case key:
    of "playlist":
      result.name = value
    of "Last-Modified":
      result.lastModification = value.parse("yyyy-MM-dd'T'HH:mm:ss'Z'")
    else:
      raise newException(CatchableError, "Unknown key: " & key)

proc getPosId*(source: MPDClient | seq[Pair]): PosId =
  for (key, value) in source:
    case key:
    of "cpos":
      result.position = value.parseUint32
    of "Id":
      result.id = value.parseUint32
    else:
      raise newException(CatchableError, "Unknown key: " & key)

proc getMount*(source: MPDClient | seq[Pair]): Mount =
  for (key, value) in source:
    case key:
    of "mount":
      result.name = value
    of "storage":
      result.storage = value
    else:
      raise newException(CatchableError, "Unknown key: " & key)

proc getSticker*(source: MPDClient | seq[Pair]): Sticker =
  for (key, value) in source:
    case key:
    of "sticker":
      let idx = value.find '='
      result.name = value[0..<idx]
      result.value = value[idx + 1..^1]
    else:
      raise newException(CatchableError, "Unknown key: " & key)

proc getFileSticker*(source: MPDClient | seq[Pair]): FileSticker =
  for (key, value) in source:
    case key:
    of "file":
      result.uri = value
    of "sticker":
      let idx = value.find '='
      result.sticker.name = value[0..<idx]
      result.sticker.value = value[idx + 1..^1]
    else:
      raise newException(CatchableError, "Unknown key: " & key)

proc getPartition*(source: MPDClient | seq[Pair]): Partition =
  result.tags = newStringTable()
  for (key, value) in source:
    case key:
    of "partition":
      result.name = value
    else:
      result.tags[key] = value

proc getOutput*(source: MPDClient | seq[Pair]): Output =
  for (key, value) in source:
    case key:
    of "outputid":
      result.id = value.parseUint32
    of "outputname":
      result.name = value
    of "plugin":
      result.plugin = value
    of "outputenabled":
      result.enabled = value.parseBool
    else:
      raise newException(CatchableError, "Unknown key: " & key)

proc getConfig*(mpd: MPDClient): Config =
  for (key, value) in mpd:
    case key:
    of "music_directory":
      result.musicDirectory = value
    else:
      raise newException(CatchableError, "Unknown key: " & key)

proc getDecoder*(source: MPDClient | seq[Pair]): Decoder =
  for (key, value) in source:
    case key:
    of "plugin":
      result.plugin = value
    of "suffix":
      result.suffixes.add value
    of "mime_type":
      result.mimeTypes.add value
    else:
      raise newException(CatchableError, "Unknown key: " & key)

proc getMessage*(source: MPDClient | seq[Pair]): Message =
  for (key, value) in source:
    case key:
    of "channel":
      result.channel = value
    of "message":
      result.message = value
    else:
      raise newException(CatchableError, "Unknown key: " & key)
