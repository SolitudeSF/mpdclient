import times, options, strutils
import ./types

func addArg*(result: var string, arg: string) {.inline.} =
  result.add escape arg

func addArg*(result: var string, arg: Filter) {.inline.} =
  result.add string arg

func addArg*(result: var string, arg: bool) {.inline.} =
  result.add if arg: '1' else: '0'

func addArg*(result: var string, arg: SongRange) {.inline.} =
  result.addInt arg.a
  result.add ':'
  result.addInt arg.b + 1

func addArg*(result: var string, arg: Duration) {.inline.} =
  result.addFloat arg.inMilliseconds.float / 1000

func addArg*(result: var string, arg: TimeRange) {.inline.} =
  result.addArg arg.a
  result.add ':'
  if arg.b.isSome: result.addArg arg.b.get

func addArg*(result: var string, arg: Slice[float]) {.inline.} =
  result.addFloat arg.a
  result.add ':'
  result.addFloat arg.b

func addArg*(result: var string, arg: Output) {.inline.} =
  result.addInt arg.id

func addArg*(result: var string, arg: AudioFormat) {.inline.} =
  if arg.rate == 0: result.add '*' else: result.addInt arg.rate
  result.add ':'
  if arg.bitDepth.bits == 0: result.add '*' else: result.add $arg.bitDepth
  result.add ':'
  if arg.channels == 0: result.add '*' else: result.addInt arg.channels

func addArg*(result: var string, arg: SortOrder) {.inline.} =
  if arg.descending: result.add '-'
  result.add $arg.tag

func addArg*(result: var string, arg: Partition | Playlist) {.inline.} =
  result.add arg.name

func addArg*(result: var string, arg: SomeFloat) {.inline.} =
  result.addFloat arg

func addArg*(result: var string, arg: SomeInteger | range) {.inline.} =
  result.addInt arg

func addArg*(result: var string, arg: Tag | ReplayGainMode | StickerOperator) {.inline.} =
  result.add $arg
