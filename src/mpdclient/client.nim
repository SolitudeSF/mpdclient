import os, net, times, options, strtabs, macros
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

proc connect(mpd: var MPDClient) =
  if mpd.host.startsWith '/':
    mpd.socket = newSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP)
    mpd.socket.connectUnix mpd.host
  else:
    mpd.socket = newSocket()
    mpd.socket.connect mpd.host, mpd.port

  if not mpd.socket.recvLine.startsWith "OK MPD ":
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
  let reply = mpd.socket.recvLine.parseReply
  if reply.kind == replyAck:
    raise newException(CatchableError, reply.ack)

proc expectList*(mpd: MPDClient): bool {.inline.} =
  let reply = mpd.socket.recvLine.parseReply
  if reply.kind == replyAck:
    raise newException(CatchableError, reply.ack)
  reply.kind == replyPair

proc send*(mpd: MPDClient, payload: string) =
  mpd.socket.send payload

proc composeCommand(cmd, args: NimNode): NimNode =
  let name = genSym nskVar
  result = newStmtList newVarStmt(name, cmd)
  for arg in args:
    result.add quote do:
      `name`.add ' '
      `name`.addArg `arg`
  result.add quote do:
    `name`.add '\n'
  result.add name

macro composeCommand*(cmd: string, args: varargs[typed]): untyped =
  composeCommand cmd, args

macro runCommand*(mpd: MPDClient, cmd: string, args: varargs[typed]) =
  newCall("send", mpd, composeCommand(cmd, args))

macro runCommandOk*(mpd: MPDClient, cmd: string, args: varargs[typed]) =
  result = newStmtList()
  var instance = mpd
  if mpd.kind == nnkCall:
    instance = genSym(nskLet)
    result.add newLetStmt(instance, mpd)
  result.add(
    newCall("send", instance, composeCommand(cmd, args)),
    newCall("expectOk", instance))

macro runCommandList*(mpd: MPDClient, cmd: string, args: varargs[typed]): bool =
  result = newStmtList()
  var instance = mpd
  if mpd.kind == nnkCall:
    instance = genSym(nskLet)
    result.add newLetStmt(instance, mpd)
  result.add(
    newCall("send", instance, composeCommand(cmd, args)),
    newCall("expectList", instance))

proc getPair*(mpd: MPDClient): Pair =
  let reply = mpd.socket.recvLine.parseReply
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

iterator values*(mpd: MPDClient): string =
  for (_, value) in mpd:
    yield value

proc getValues*(mpd: MPDClient): seq[string] =
  for val in mpd.values:
    result.add val

func getComponent*(result: var Status, key, value: string) =
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

func getComponent*(result: var Stats, key, value: string) =
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

proc getComponent*(result: var Song, key, value: string) =
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

proc getComponent*(result: var Playlist, key, value: string) =
  case key:
  of "playlist":
    result.name = value
  of "Last-Modified":
    result.lastModification = value.parse("yyyy-MM-dd'T'HH:mm:ss'Z'")
  else:
    raise newException(CatchableError, "Unknown key: " & key)

func getComponent*(result: var PosId, key, value: string) =
  case key:
  of "cpos":
    result.position = value.parseUint32
  of "Id":
    result.id = value.parseUint32
  else:
    raise newException(CatchableError, "Unknown key: " & key)

func getComponent*(result: var Mount, key, value: string) =
  case key:
  of "mount":
    result.name = value
  of "storage":
    result.storage = value
  else:
    raise newException(CatchableError, "Unknown key: " & key)

func getComponent*(result: var Sticker, key, value: string) =
  case key:
  of "sticker":
    let idx = value.find '='
    result.name = value[0..<idx]
    result.value = value[idx + 1..^1]
  else:
    raise newException(CatchableError, "Unknown key: " & key)

func getComponent*(result: var FileSticker, key, value: string) =
  case key:
  of "file":
    result.uri = value
  of "sticker":
    let idx = value.find '='
    result.sticker.name = value[0..<idx]
    result.sticker.value = value[idx + 1..^1]
  else:
    raise newException(CatchableError, "Unknown key: " & key)

func getComponent*(result: var Partition, key, value: string) =
  case key:
  of "partition":
    result.name = value
  else:
    result.tags[key] = value

func getComponent*(result: var Output, key, value: string) =
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

func getComponent*(result: var Config, key, value: string) =
  case key:
  of "music_directory":
    result.musicDirectory = value
  else:
    raise newException(CatchableError, "Unknown key: " & key)

func getComponent*(result: var Decoder, key, value: string) =
  case key:
  of "plugin":
    result.plugin = value
  of "suffix":
    result.suffixes.add value
  of "mime_type":
    result.mimeTypes.add value
  else:
    raise newException(CatchableError, "Unknown key: " & key)

func getComponent*(result: var Message, key, value: string) =
  case key:
  of "channel":
    result.channel = value
  of "message":
    result.message = value
  else:
    raise newException(CatchableError, "Unknown key: " & key)

proc get*[T](mpd: MPDClient, result: var T) =
  when T is Song:
    result.tags = newStringTable()
  for (key, value) in mpd:
    result.getComponent key, value

proc get*[T](mpd: MPDClient, t: typedesc[T]): T =
  mpd.get result

iterator structs*[T](mpd: MPDClient; firstKey: string, t: typedesc[T]): T =
  var
    first = true
    res: t
  when t is Song:
    res.tags = newStringTable()
  for (key, value) in mpd:
    if key == firstKey:
      if not first:
        yield res
        reset res
        when t is Song:
          res.tags = newStringTable()
      else:
        first = false
    res.getComponent key, value
  yield res
