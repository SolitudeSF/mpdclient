import times, strtabs, options

type
  State* = enum
    stateStop = "stop", statePlay = "play", statePause = "pause"

  QueuePlace* = object
    id*, pos*: uint32
    priority*: uint8

  Filter* = distinct string

  SongRange* = Slice[uint32]

  TimeRange* = HSlice[Duration, Option[Duration]]

  SubsystemKind* = enum
    subDatabase = "database", subUpdate = "update", subStoredPlaylist = "stored_playlist",
    subPlaylist = "playlist", subPlayer = "player", subMixer = "mixer",
    subOutput = "output", subOptions = "options", subPartition = "partition",
    subSticker = "sticker", subSubscription = "subscribtion", subMessage = "message"

  Song* = object
    file*, name*, title*: string
    artists*: seq[string]
    place*: Option[QueuePlace]
    lastModification*: DateTime
    duration*: Duration
    audio*: AudioFormat
    range*: TimeRange
    tags*: StringTableRef

  Stats* = object
    artists*, albums*, songs*: uint32
    uptime*, playtime*, dbPlaytime*: Duration
    dbUpdate*: Time

  ReplayGainMode* = enum
    gainOff = "off", gainTrack = "track", gainAlbum = "album", gainAuto = "auto"

  BitDepthKind* = enum
    bdFixed, bdFloating

  BitDepth* = object
    kind*: BitDepthKind
    bits*: uint8

  AudioFormat* = object
    rate*: uint32
    bitDepth*: BitDepth
    channels*: uint8

  Status* = object
    partition*: string
    volume*: int8
    repeat*, random*, single*, consume*: bool
    queueVersion*, queueLen*, bitrate*: uint32
    state*: State
    song*, nextSong*: Option[QueuePlace]
    time*: (Duration, Duration)
    elapsed*, duration*, crossfade*, mixrampdelay*: Duration
    mixrampdb*: float32
    audio*: AudioFormat
    updatingDb*: Option[uint32]
    error*: Option[string]

  Tag* = enum
    tagAny = "any"
    tagArtist = "Artist"
    tagArtistSort = "ArtistSort"
    tagAlbum = "Album"
    tagAlbumSort = "AlbumSort"
    tagAlbumArtist = "AlbumArtist"
    tagAlbumArtistSort = "AlbumArtistSort"
    tagTitle = "Title"
    tagTrack = "Track"
    tagName = "Name"
    tagGenre = "Genre"
    tagDate = "Date"
    tagOriginalDate = "OriginalDate"
    tagComposer = "Composer"
    tagComposerSort = "ComposerSort"
    tagPerformer = "Performer"
    tagConductor = "Conductor"
    tagEnseble = "Enseble"
    tagMovement = "Movement"
    tagMovementNumber = "MovementNumber"
    tagWork = "Work"
    tagGrouping = "Grouping"
    tagDisc = "Disc"
    tagLabel = "Label"
    tagLocation = "Location"
    tagMUSICBRAINZ_ARTISTID = "MUSICBRAINZ_ARTISTID"
    tagMUSICBRAINZ_ALBUMID = "MUSICBRAINZ_ALBUMID"
    tagMUSICBRAINZ_ALBUMARTISTID = "MUSICBRAINZ_ALBUMARTISTID"
    tagMUSICBRAINZ_TRACKID = "MUSICBRAINZ_TRACKID"
    tagMUSICBRAINZ_RELEASETRACKID = "MUSICBRAINZ_RELEASETRACKID"
    tagMUSICBRAINZ_WORKID = "MUSICBRAINZ_WORKID"

  SortOrder* = object
    tag*: Tag
    descending*: bool

  CountGroup* = object
    tag*: Tag
    name*: string
    songs*, playtime*: int

  Playlist* = object
    name*: string
    lastModification*: DateTime

  InfoEntryKind* = enum
    entryDirectory, entryFile, entryPlaylist

  InfoEntry* = object
    kind*: InfoEntryKind
    name*: string
    tags*: StringTableRef

  PosId* = tuple[position, id: uint32]

  Sticker* = tuple[name, value: string]

  FileSticker* = tuple[uri: string, sticker: Sticker]

  Directory* = object
    name*: string
    lastModification*: DateTime

  StickerOperator* = enum
    stOpEquals = "=", stOpMore = ">", stOpLess = "<"

  Mount* = object
    name*, storage*: string

  Neighbor* = Mount

  Partition* = object
    name*: string
    tags*: StringTableRef

  Output* = object
    id*: uint32
    name*, plugin*: string
    enabled*: bool

  Config* = object
    musicDirectory*: string

  Decoder* = object
    plugin*: string
    suffixes*, mimeTypes*: seq[string]

  Message* = object
    channel*, message*: string

const noSort* = SortOrder(tag: tagAny)

proc `$`*(b: BitDepth): string =
  case b.kind
  of bdFixed:
    $b.bits
  of bdFloating:
    "f"

proc `$`*(a: AudioFormat): string = $a.rate & ":" & $a.bitDepth & ":" & $a.channels

func sortBy*(tag: Tag, descending = false): SortOrder =
  SortOrder(tag: tag, descending: descending)
