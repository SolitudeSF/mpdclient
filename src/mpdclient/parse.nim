import macros, times, strutils, options
import ./types

macro parseEnum(s: string, t: typed): untyped =
  result = newNimNode(nnkCaseStmt).add(s)
  for c in t.getImpl[2][1..^1]:
    let (v, e) = block:
      case c.kind
      of nnkEnumFieldDef: (c[1], c[0])
      else: (newCall(ident"$", c), c)
    result.add newNimNode(nnkOfBranch).add(v, e)

  result.add newNimNode(nnkElse).add(quote do:
    raise newException(CatchableError, "Couldn't parse " & $`t` & ": " & $`s`))

func parseSubsystem*(s: string): SubsystemKind = s.parseEnum SubsystemKind
func parseState*(s: string): State = s.parseEnum State
func parseReplayGainMode*(s: string): ReplayGainMode = s.parseEnum ReplayGainMode

template parseUint32*(s: string): uint32 = s.parseInt.uint32

func parseBool*(s: string): bool = s == "1"

func parseFloatSeconds*(s: string): Duration =
  initDuration(milliseconds = int(s.parseFloat * 1000))

func parseTimeRange*(s: string): TimeRange =
  let idx = s.find '-'
  result.a = s[0..<idx].parseFloatSeconds
  if idx < s.high:
    result.b = some(s[idx + 1..^1].parseFloatSeconds)

func parseTime*(s: string): (Duration, Duration) =
  let idx = s.find ':'
  (s[0..<idx].parseFloatSeconds, s[idx + 1..^1].parseFloatSeconds)

func parseBitDepth*(s: string): BitDepth =
  if s == "f":
    BitDepth(kind: bdFloating, bits: 32)
  else:
    BitDepth(kind: bdFixed, bits: s.parseInt.uint8)

func parseAudioFormat*(s: string): AudioFormat =
  let
    idx1 = s.find ':'
    idx2 = s.find(':', start = idx1 + 1)
  result.rate = s[0..<idx1].parseUint32
  result.bitDepth = s[idx1 + 1..<idx2].parseBitDepth
  result.channels = s[idx2 + 1..^1].parseInt.uint8
