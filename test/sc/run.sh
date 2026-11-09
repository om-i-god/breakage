#!/bin/sh
# usage: test/sc/run.sh [extra.scd]
# compiles lib/Engine_Breakage.sc against a stub CroneEngine, boots a local
# server, fires every command (or runs extra.scd with ~eng set), renders a
# wav and prints its levels. killed after 1200s if sclang hangs.
#
# the stub lives as CroneStub.stub so it can never be compiled on a norns
# (a second CroneEngine class there = "DUPLICATE ENGINES"); it's copied to a
# temp class dir as .sc only for this run.
EXTRA=""
[ -n "$1" ] && EXTRA="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
cd "$(dirname "$0")"
SCLANG=/Applications/SuperCollider.app/Contents/MacOS/sclang
OUT="${TMPDIR:-/tmp}/breakage_test.wav"
LIB="${TMPDIR:-/tmp}/breakage_sclib"
rm -rf "$LIB"; mkdir -p "$LIB"
cp CroneStub.stub "$LIB/CroneStub.sc"
cat > "$LIB/lang.yaml" <<YAML
includePaths:
  - $LIB
  - $(cd ../../lib && pwd)
excludePaths: []
postInlineWarnings: false
YAML
# sclang writes to a file, not a pipe: if it is killed, an orphaned scsynth
# would otherwise hold the pipe open and hang the run
LOG="${TMPDIR:-/tmp}/breakage_test.log"
perl -e 'alarm 1200; exec @ARGV' "$SCLANG" -l "$LIB/lang.yaml" run.scd "$OUT" $EXTRA > "$LOG" 2>&1
grep -E "ERROR|WARNING|FAILURE|ENGINE|SMOKE|LEVELS|SEG|poll |Message|RECEIVER|not understood|nil|CHECK|exception|Exception|error|late|breakage:" "$LOG" \
  | grep -v "^Exception in World_OpenUDP"
# belt and braces: never leave a test server behind
pkill -f "SuperCollider.app/Contents/Resources/../Resources/scsynth" 2>/dev/null
exit 0
