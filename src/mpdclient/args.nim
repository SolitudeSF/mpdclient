import times, options
import ./types

func toArg*(arg: string): string {.inline.} = arg

func toArg*(arg: Filter): string {.inline.} = string arg

func toArg*(arg: bool): string {.inline.} = (if arg: "1" else: "0")

func toArg*(arg: SongRange): string {.inline.} = $arg.a & ":" & $(arg.b + 1)

func toArg*(arg: Duration): string {.inline.} =
  $(arg.inMilliseconds.float / 1000)

func toArg*(arg: TimeRange): string {.inline.} =
  $arg.a & ":" & (if arg.b.isSome: arg.b.get.toArg else: "")

func toArg*(arg: HSlice[float, float]): string {.inline.} = $arg.a & ":" & $arg.b

func toArg*(arg: Output): string {.inline.} = $arg.id

func toArg*(arg: AudioFormat): string {.inline.} =
  (if arg.rate == 0: "*" else: $arg.rate) & ":" &
  (if arg.bitDepth.bits == 0: "*" else: $arg.bitDepth) & ":" &
  (if arg.channels == 0: "*" else: $arg.channels)

func toArg*(arg: SortOrder): string {.inline.} =
  (if arg.descending: "-" else: "") & $arg.tag

func toArg*(arg: Partition | Playlist): string {.inline.} = arg.name

func toArg*[T](arg: T): string {.inline.} = $arg
