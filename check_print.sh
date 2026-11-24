#!/usr/bin/env bash
# Export the print layout (show="print") and check it for suction cups.
#
# Usage:
#   ./check_print.sh [-o plate.stl] [-D var=val ...] [file.scad]
#
# Writes:
#   plate.stl  - base, lid and core in print orientation, ready for the slicer
#   cups.stl   - next to the .scad, the cup volumes (what show_cups overlays)
#   cups.png   - plan view, cups in red
# Then tick show_cups in OpenSCAD's Customizer (or -D show_cups=true) with
# show = "print" to see any cups in red on the model.
#
# Exit code: 0 = no cups, 1 = cups found, 2 = error.
# Needs: openscad, and cupcheck.py next to this script. Python: uses $PYTHON if set,
# else .venv/bin/python next to this script if it exists, else python3. One-off setup:
#   python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
PLATE=plate.stl
DEFINES=()
while getopts "o:D:h" opt; do
    case $opt in
        o) PLATE=$OPTARG ;;
        D) DEFINES+=(-D "$OPTARG") ;;
        h) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))
SCAD=${1:-mould.scad}
[[ -f $SCAD ]] || { echo "error: $SCAD not found" >&2; exit 2; }
SCAD_DIR=$(cd "$(dirname "$SCAD")" && pwd)

if   [[ -n ${PYTHON:-} ]];              then PY=$PYTHON
elif [[ -x $HERE/.venv/bin/python ]];  then PY=$HERE/.venv/bin/python
else                                         PY=python3
fi
if ! "$PY" -c "import numpy, trimesh, scipy, PIL, networkx" 2>/dev/null; then
    echo "error: $PY is missing packages. Set up the venv once with:" >&2
    echo "  python3 -m venv $HERE/.venv && $HERE/.venv/bin/pip install -r $HERE/requirements.txt" >&2
    exit 2
fi

echo "exporting $PLATE"
LOG=$(mktemp); trap 'rm -f "$LOG"' EXIT
if ! openscad "$SCAD" -D 'show="print"' -D show_cups=false "${DEFINES[@]}" -o "$PLATE" >"$LOG" 2>&1; then
    cat "$LOG" >&2; echo "error: openscad export failed" >&2; exit 2
fi
grep -E "WARNING|ERROR" "$LOG" >&2 || true

echo "checking for suction cups"
set +e
"$PY" -I "$HERE/cupcheck.py" "$PLATE" --stl-out "$SCAD_DIR/cups.stl" --png "$SCAD_DIR/cups.png"
rc=$?
set -e
if [[ $rc == 1 ]]; then
    echo "cups found - open $SCAD with show=\"print\" and show_cups ticked to see them" >&2
fi
exit $rc
