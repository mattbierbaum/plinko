import std/strutils

proc indent*(s: string, indent: string = "  "): string =
    var lines = s.split("\n")
    var output = ""
    for line in lines:
        if line.len > 0:
            output &= indent & line.strip(chars={'\n'}) & "\n"
    return output