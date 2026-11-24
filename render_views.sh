#!/usr/bin/env bash
# Render the standard documentation views of the mould:
#   core-pin.png  - the ejector core pin on its own
#   exploded.png  - exploded assembly
#   section.png   - side-on cutaway through the cavity
#
# Usage:
#   ./render_views.sh [options] [file.scad]
#
# Options:
#   -o DIR     output directory              (default: renders)
#   -s WxH     image size in pixels          (default: 2240,1496)
#   -c SCHEME  OpenSCAD colour scheme         (default: Cornfield)
#   -r         full CGAL/Manifold render instead of preview (slower; some
#              OpenSCAD versions drop colours in this mode)
#   -n         no auto-crop (only the section view is cropped; the axis views
#              keep OpenSCAD's full frame because the axes run to the edges)
#   -v         verbose: show OpenSCAD's ECHO output (diagnostics) too
#   -D var=val extra OpenSCAD define, passed straight through (repeatable),
#              e.g. -D 'label_text="R3"' -D explode=30
#   -h         help
#
# Needs: openscad. Optional: ImageMagick (magick or convert) for cropping,
# xvfb-run if there is no display (e.g. over SSH / in CI).

set -euo pipefail

OUT=images
SIZE=2240,1496
SCHEME=Cornfield
RENDER=()
CROP=1
DEFINES=()
VERBOSE=0

usage() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while getopts "o:s:c:rnvD:h" opt; do
    case $opt in
        o) OUT=$OPTARG ;;
        s) SIZE=${OPTARG/x/,} ;;
        c) SCHEME=$OPTARG ;;
        r) RENDER=(--render) ;;
        n) CROP=0 ;;
        v) VERBOSE=1 ;;
        D) DEFINES+=(-D "$OPTARG") ;;
        h) usage 0 ;;
        *) usage 1 ;;
    esac
done
shift $((OPTIND - 1))
SCAD=${1:-mould.scad}

[[ -f $SCAD ]] || { echo "error: $SCAD not found" >&2; exit 1; }
command -v openscad >/dev/null || { echo "error: openscad not on PATH" >&2; exit 1; }
mkdir -p "$OUT"

# Headless fallback: OpenSCAD needs an OpenGL context to write PNGs.
RUN=()
if [[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]] && command -v xvfb-run >/dev/null; then
    RUN=(xvfb-run -a)
fi

# ImageMagick 7 is "magick", 6 is "convert"
IM=""
if   command -v magick  >/dev/null; then IM=magick
elif command -v convert >/dev/null; then IM=convert
fi
if [[ $CROP == 1 && -z $IM ]]; then
    echo "note: ImageMagick not found - images will not be cropped" >&2
fi

LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

# render NAME SHOW CAMERA CROP(0/1) [extra openscad args...]
# CAMERA is OpenSCAD's gimbal form: tx,ty,tz,rot_x,rot_y,rot_z,dist
# --viewall/--autocenter fit the model to the frame, so tx..tz and dist only
# matter if you remove those flags.
render() {
    local name=$1 show=$2 camera=$3 crop=$4; shift 4
    local png="$OUT/$name.png"
    local fit=(--viewall --autocenter)
    if [[ ${1:-} == --noviewall ]]; then fit=(); shift; fi
    echo "rendering $png"
    if ! "${RUN[@]}" openscad "$SCAD" -o "$png" \
            -D "show=\"$show\"" "${DEFINES[@]}" \
            --imgsize="$SIZE" --colorscheme="$SCHEME" \
            --camera="$camera" "${fit[@]}" \
            "${RENDER[@]}" "$@" >"$LOG" 2>&1; then
        cat "$LOG" >&2
        echo "error: openscad failed on $name" >&2
        exit 1
    fi
    if [[ $VERBOSE == 1 ]]; then grep "ECHO" "$LOG" | sort -u || true; fi
    grep -E "WARNING|ERROR" "$LOG" | sed "s/^/  [$name] /" >&2 || true
    if [[ $CROP == 1 && $crop == 1 && -n $IM ]]; then
        # Trim the flat background, then add a small even margin back
        local bg
        bg=$("$IM" "$png" -format '%[pixel:p{0,0}]' info:)
        "$IM" "$png" -fuzz 2% -trim +repage \
            -bordercolor "$bg" -border 40 "$png"
    fi
}

# Core pin: lower and turned so the dowel-hole face is towards the camera
render core-pin core 0,0,0,70,0,120,0 0 --view=axes,scales

# Exploded: --autocenter would centre on the bounding box, which includes the dowel
# (shifted sideways by `explode`), so the stack ends up off-centre. Instead ask the
# model for the stack's vertical centre and height, aim the camera at (0, 0, centre)
# and back it off far enough to fit the stack.
# NOTE: this reads variables from mould.scad (explode, with_rubber, base_h,
# lid_thickness, total_h, box_w, box_l) - update here if they're renamed.
EXP_RX=55; EXP_RZ=25; FILL=0.85   # FILL = fraction of image height the stack uses
ECHO_FILE=$(mktemp --suffix=.echo)
openscad "$SCAD" -o "$ECHO_FILE" -D 'show="none"' "${DEFINES[@]}" \
    -D '_vb = -explode' \
    -D '_vt = with_rubber ? base_h + lid_thickness + 2 * explode + total_h : base_h + lid_thickness + explode' \
    -D '_vd = sqrt(box_w * box_w + box_l * box_l)' \
    -D '_vx = echo(str("VIEW=", (_vb + _vt) / 2, ",", _vt - _vb, ",", _vd)) 0' >/dev/null 2>&1 || true
VIEW=$(grep -o 'VIEW=[-0-9.e,]*' "$ECHO_FILE" | head -1 | cut -d= -f2)
rm -f "$ECHO_FILE"
if [[ -n $VIEW ]]; then
    IFS=, read -r ZC HT DIAG <<<"$VIEW"
    W=${SIZE%,*}; H=${SIZE#*,}
    # Projected height on screen ~ HT*sin(rx) + DIAG*cos(rx). OpenSCAD's default
    # field of view is 22.5 deg, so visible height at distance d is 2*d*tan(11.25).
    # Also check width (aspect) so a wide image doesn't clip the dowel.
    DIST=$(awk -v ht="$HT" -v dg="$DIAG" -v rx="$EXP_RX" -v fill="$FILL" -v w="$W" -v h="$H" 'BEGIN {
        pi = atan2(0, -1); r = rx * pi / 180
        ph = ht * sin(r) + dg * cos(r)              # projected height
        pw = dg                                      # rough projected width
        t  = 2 * sin(11.25 * pi / 180) / cos(11.25 * pi / 180)
        dh = ph / (t * fill)
        dw = pw / (t * fill * w / h)
        printf "%.1f", (dh > dw ? dh : dw) }')
    render exploded exploded "0,0,$ZC,$EXP_RX,0,$EXP_RZ,$DIST" 0 --noviewall --view=axes,scales
else
    echo "note: couldn't read stack size from $SCAD - falling back to --autocenter" >&2
    render exploded exploded 0,0,0,$EXP_RX,0,$EXP_RZ,0 0 --view=axes,scales
fi
# Side-on, orthographic, looking at the cut face (cut keeps y <= 0, so look from +y)
render section  section  0,0,0,90,0,180,0 1 --projection=o

echo "done: $OUT/{core-pin,exploded,section}.png"
