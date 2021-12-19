import macros, times, options
import ./types

func `$`*(s: openArray[char]): string =
  result = newString s.len
  copymem addr result[0], unsafeAddr s[0], s.len

func rawParseInt(s: openArray[char], b: var BiggestInt, start = 0): int =
  var
    sign: BiggestInt = -1
    i = start
  if i < s.len:
    if s[i] == '+': inc(i)
    elif s[i] == '-':
      inc(i)
      sign = 1
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      let c = ord(s[i]) - ord('0')
      if b >= (low(BiggestInt) + c) div 10:
        b = b * 10 - c
      else:
        raise newException(ValueError, "Parsed integer outside of valid range")
      inc(i)
      while i < s.len and s[i] == '_': inc(i)
    if sign == -1 and b == low(BiggestInt):
      raise newException(ValueError, "Parsed integer outside of valid range")
    else:
      b = b * sign
      result = i - start

func parseInt*(s: openArray[char]): BiggestInt =
  discard s.rawParseInt result

const
  IdentChars = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
  powtens =  [1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9,
              1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
              1e20, 1e21, 1e22]

func c_strtod(buf: cstring, endptr: ptr cstring): float64 {.importc: "strtod", header: "<stdlib.h>".}

func parseBiggestFloat(s: openArray[char], number: var BiggestFloat, start = 0): int =
  var
    i = start
    sign = 1.0
    kdigits, fdigits = 0
    exponent = 0
    integer = uint64(0)
    fracExponent = 0
    expSign = 1
    firstDigit = -1
    hasSign = false

  # Sign?
  if i < s.len and (s[i] == '+' or s[i] == '-'):
    hasSign = true
    if s[i] == '-':
      sign = -1.0
    inc(i)

  # NaN?
  if i+2 < s.len and (s[i] == 'N' or s[i] == 'n'):
    if s[i+1] == 'A' or s[i+1] == 'a':
      if s[i+2] == 'N' or s[i+2] == 'n':
        if i+3 >= s.len or s[i+3] notin IdentChars:
          number = NaN
          return i+3 - start
    return 0

  # Inf?
  if i+2 < s.len and (s[i] == 'I' or s[i] == 'i'):
    if s[i+1] == 'N' or s[i+1] == 'n':
      if s[i+2] == 'F' or s[i+2] == 'f':
        if i+3 >= s.len or s[i+3] notin IdentChars:
          number = Inf*sign
          return i+3 - start
    return 0

  if i < s.len and s[i] in {'0'..'9'}:
    firstDigit = (s[i].ord - '0'.ord)
  # Integer part?
  while i < s.len and s[i] in {'0'..'9'}:
    inc(kdigits)
    integer = integer * 10'u64 + (s[i].ord - '0'.ord).uint64
    inc(i)
    while i < s.len and s[i] == '_': inc(i)

  # Fractional part?
  if i < s.len and s[i] == '.':
    inc(i)
    # if no integer part, Skip leading zeros
    if kdigits <= 0:
      while i < s.len and s[i] == '0':
        inc(fracExponent)
        inc(i)
        while i < s.len and s[i] == '_': inc(i)

    if firstDigit == -1 and i < s.len and s[i] in {'0'..'9'}:
      firstDigit = (s[i].ord - '0'.ord)
    # get fractional part
    while i < s.len and s[i] in {'0'..'9'}:
      inc(fdigits)
      inc(fracExponent)
      integer = integer * 10'u64 + (s[i].ord - '0'.ord).uint64
      inc(i)
      while i < s.len and s[i] == '_': inc(i)

  # if has no digits: return error
  if kdigits + fdigits <= 0 and
     (i == start or # no char consumed (empty string).
     (i == start + 1 and hasSign)): # or only '+' or '-
    return 0

  if i+1 < s.len and s[i] in {'e', 'E'}:
    inc(i)
    if s[i] == '+' or s[i] == '-':
      if s[i] == '-':
        expSign = -1

      inc(i)
    if s[i] notin {'0'..'9'}:
      return 0
    while i < s.len and s[i] in {'0'..'9'}:
      exponent = exponent * 10 + (ord(s[i]) - ord('0'))
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored

  var realExponent = expSign*exponent - fracExponent
  let expNegative = realExponent < 0
  var absExponent = abs(realExponent)

  # if exponent greater than can be represented: +/- zero or infinity
  if absExponent > 999:
    if expNegative:
      number = 0.0*sign
    else:
      number = Inf*sign
    return i - start

  # if integer is representable in 53 bits:  fast path
  # max fast path integer is  1<<53 - 1 or  8999999999999999 (16 digits)
  let digits = kdigits + fdigits
  if digits <= 15 or (digits <= 16 and firstDigit <= 8):
    # max float power of ten with set bits above the 53th bit is 10^22
    if absExponent <= 22:
      if expNegative:
        number = sign * integer.float / powtens[absExponent]
      else:
        number = sign * integer.float * powtens[absExponent]
      return i - start

    # if exponent is greater try to fit extra exponent above 22 by multiplying
    # integer part is there is space left.
    let slop = 15 - kdigits - fdigits
    if absExponent <= 22 + slop and not expNegative:
      number = sign * integer.float * powtens[slop] * powtens[absExponent-slop]
      return i - start

  # if failed: slow path with strtod.
  var t: array[500, char] # flaviu says: 325 is the longest reasonable literal
  var ti = 0
  let maxlen = t.high - "e+000".len # reserve enough space for exponent

  let endPos = i
  result = endPos - start
  i = start
  # re-parse without error checking, any error should be handled by the code above.
  if i < endPos and s[i] == '.': i.inc
  while i < endPos and s[i] in {'0'..'9','+','-'}:
    if ti < maxlen:
      t[ti] = s[i]; inc(ti)
    inc(i)
    while i < endPos and s[i] in {'.', '_'}: # skip underscore and decimal point
      inc(i)

  # insert exponent
  t[ti] = 'E'
  inc(ti)
  t[ti] = if expNegative: '-' else: '+'
  inc(ti, 4)

  # insert adjusted exponent
  t[ti-1] = ('0'.ord + absExponent mod 10).char
  absExponent = absExponent div 10
  t[ti-2] = ('0'.ord + absExponent mod 10).char
  absExponent = absExponent div 10
  t[ti-3] = ('0'.ord + absExponent mod 10).char
  number = c_strtod(addr t, nil)

func parseFloat*(s: openArray[char]): BiggestFloat =
  discard s.parseBiggestFloat result

func startsWith*(o: openArray[char], s: string): bool =
  o.len >= s.len and cmpMem(unsafeAddr o[0], unsafeAddr s[0], s.len) == 0

func `==`(o: openArray[char], s: string): bool =
  o.len == s.len and cmpMem(unsafeAddr o[0], unsafeAddr s[0], o.len) == 0

func find[T](o: openArray[T], item: T, start: int): int =
  for i in start..<o.len:
    if o[i] == item: return i
  return -1

macro parseEnum(s: openArray[char], t: typed): untyped =
  result = newNimNode nnkIfStmt
  for c in t.getImpl[2][1..^1]:
    let (v, e) = block:
      case c.kind
      of nnkEnumFieldDef: (c[1], c[0])
      else: (newCall(ident"$", c), c)
    result.add nnkElifBranch.newTree(newCall("==", s, v), e)

  result.add nnkElse.newTree quote do:
    raise newException(CatchableError, "Couldn't parse " & $`t` & ": " & $`s`)

func parseSubsystem*(s: openArray[char]): SubsystemKind = s.parseEnum SubsystemKind
func parseState*(s: openArray[char]): State = s.parseEnum State
func parseReplayGainMode*(s: openArray[char]): ReplayGainMode = s.parseEnum ReplayGainMode

func parseUint32*(s: openArray[char]): uint32 = s.parseInt.uint32

func parseBool*(s: openArray[char]): bool = s == "1"

func parseFloatSeconds*(s: openArray[char]): Duration =
  initDuration(milliseconds = int(s.parseFloat * 1000))

func parseTimeRange*(s: openArray[char]): TimeRange =
  let idx = s.find '-'
  result.a = s.toOpenArray(0, idx - 1).parseFloatSeconds
  if idx < s.high:
    result.b = some(s.toOpenArray(idx + 1, s.len - 1).parseFloatSeconds)

func parseTime*(s: openArray[char]): (Duration, Duration) =
  let idx = s.find ':'
  (s.toOpenArray(0, idx - 1).parseFloatSeconds, s.toOpenArray(idx + 1, s.len - 1).parseFloatSeconds)

func parseBitDepth*(s: openArray[char]): BitDepth =
  if s == "f":
    BitDepth(kind: bdFloating, bits: 32)
  else:
    BitDepth(kind: bdFixed, bits: s.parseInt.uint8)

func parseAudioFormat*(s: openArray[char]): AudioFormat =
  let
    idx1 = s.find ':'
    idx2 = s.find(':', start = idx1 + 1)
  result.rate = s.toOpenArray(0, idx1 - 1).parseUint32
  result.bitDepth = s.toOpenArray(idx1 + 1, idx2 - 1).parseBitDepth
  result.channels = s.toOpenArray(idx2 + 1, s.len - 1).parseInt.uint8
