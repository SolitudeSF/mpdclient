import strutils
import ./types, ./args

proc `&=`(a: var Filter, b: Filter) {.borrow.}
proc `&`(a, b: Filter): Filter {.borrow.}

func tagEquals*(t: Tag, s: string): Filter =
  var res = "("
  res.addArg t
  res.add " == "
  res.addArg s
  res.add ')'
  Filter res

func tagContains*(t: Tag, s: string): Filter =
  var res = "("
  res.addArg t
  res.add " contains "
  res.addArg s
  res.add ')'
  Filter res

func tagMatches*(t: Tag, s: string): Filter =
  var res = "("
  res.addArg t
  res.add " =~ "
  res.addArg s
  res.add ')'

func tagNotMatches*(t: Tag, s: string): Filter =
  var res = "("
  res.addArg t
  res.add " !~ "
  res.addArg s
  res.add ')'
  Filter res

func fileEquals*(t, s: string): Filter = Filter("(file == " & s.escape & ")")
func base*(s: string): Filter = Filter("(base " & s.escape & ")")
func modifiedSince*(s: string): Filter = Filter("(modified-since " & s.escape & ")")
func audioFormatEquals*(s: string | AudioFormat): Filter = Filter("(AudioFormat == " & $s.escape & ")")
func audioFormatMatches*(a: string | AudioFormat): Filter =
  var res = "(AudioFormat =~ "
  res.add a.toArg.escape
  res.add ')'
  Filter res

func `not`*(e: Filter): Filter = Filter("(!" & e.string & ")")
func `and`*(a, b: Filter): Filter = Filter("(" & a.string & " and " & b.string & ")")
func `and`*(e: varargs[Filter]): Filter =
  if e.len > 0:
    result = Filter("(") & e[0]
    for i in 1..e.high:
      result &= Filter " and "
      result &= e[i]
    result &= Filter ")"
