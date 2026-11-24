// Door catch rubber insert + 2-part casting mould (with removable core pins)
// Units: millimetres
//
// Mould concept
//   - Part is cast LIP-DOWN. The body tapers towards the lip, so the cavity is a
//     simple pocket that widens upwards: it releases straight up with no split.
//   - BASE: solid block holding all cavities. Parting plane = the flat bottom face
//     of the rubber part, so the LID is just a flat plate (gives a clean flat face).
//   - EJECTOR CORE PIN: the stud-shaped hole (funnel + collar + neck + mushroom head)
//     is formed by a separate pin. Its top is a plate the exact size of the lip face,
//     so it forms the whole floor of the lip pocket. Below the plate is a narrower
//     stem that runs to the underside of the base. A 45 deg chamfer between plate
//     and stem sits in a matching seat, so the pin cannot drop, but it can be pushed
//     UP. Print orientation: base upright on the plate; lid top-face-down on the
//     plate; pin upright, supported only under the stem - no supports needed on
//     any mould surface.
//     A cross-dowel (cocktail stick / wire / printed pin) through the side of the
//     base and the stem stops the pin floating while the rubber cures.
//     To demould: lift the lid, pull the dowel, push the stem up from below - the
//     part rises out of the cavity sitting on the pin - then peel it off by hand.
//   - LID: one sprue (with funnel) + two vents per cavity, plus alignment pins.
//     Either pour through the sprues, or overfill the open cavities and press the
//     lid down so the excess bleeds out of the holes.

/* [What to render] */
show = "assembly"; // [part, base, lid, core, cores, assembly, exploded, section, print]
with_rubber = true; // Show the part

/* [Part dimensions] */
outer_width  = 18.5;   // Base width of the rubber part
outer_length = 23.0;   // Base length of the rubber part
outer_height = 9.5;    // Height of the rubber part, not including lip

// NOTE: this is a linear_extrude SCALE factor, not an angle (0.95 = top is 95% of base)
draft_scale   = 0.95;
body_corner_radius = 3.0;  // Base body corners. Rough check on the original: about a 5 mm drill shank (r 2.5), sides also bulge, so rounded up
lip_corner_radius  = 1.5;  // Lip corners - not yet measured

lip_width  = 12.5;     // Width of the upper locating lip
lip_length = 14.5;     // Length of the upper locating lip
lip_height = 4.0;      // Height of the upper locating lip

/* [Stud / hole] */
ball_dia            = 8.2;   // Max diameter of the mushroom head
ball_height         = 6.0;   // Height of the head
ball_shaft_length   = 11;    // Stud length from lip face to tip
ball_shaft_diameter = 5.0;   // Stud neck diameter
ball_spacing        = 0.2;   // Radial padding added to the hole (core pin)

detent_height        = lip_height * 0.9; // Depth of the lead-in funnel
detent_top_scale     = 0.35;             // Funnel bottom size as fraction of its mouth
detent_lip_scale     = 0.8;              // Funnel mouth size as fraction of lip
detent_corner_radius = 2;
collar_dia_scale     = 1.2;              // Collar dia = shaft dia * this

/* [Mould] */
tolerance      = 0.15;  // Added to body w/l/h (see notes: shrink is really a %)
mold_thickness = 8.0;   // Outer walls and floor
cavity_gap     = 6.0;   // Wall between neighbouring cavities
cols = 1;   // set 2 x 2 once the single-cavity design is dialled in
rows = 1;
lid_thickness  = 5.0;   // 6 if lid_grooves is on (room for grooves above the blind pin holes)

pin_dia        = 4.0;   // Alignment pin diameter
pin_inset      = 5.0;   // Pin centre distance in from the outside edges (was mold_thickness/2 = 4)
key_pin_extra  = 1.0;   // One pin is this much bigger so the lid only fits one way
pin_height     = 4.0;
pin_clearance  = 0.2;   // Diametral clearance in lid holes

sprue_dia        = 3.5;
sprue_funnel_dia = 8.0;
vent_dia         = 1.5;
vent_inset       = 2.5; // Vent distance in from cavity edge
vent_countersink = 1.0; // 45 deg countersink depth on the lid's TOP face, so the
                        // over-exposed burn-in layers (lid printed top-face-down)
                        // can't close the vents. 0 = off.

integral_cores = false; // true = cores printed as part of the base (no pins)
core_clearance = 0.08;  // Radial clearance of the pin PLATE in its pocket (sets lip-face flash - keep tight)
stem_clearance = 0.25;  // Radial clearance of the pin STEM in its hole. Doesn't seal anything,
                        // so it can be loose - the plate and 45 deg seat do the locating.
plate_t        = 2.0;   // Straight-sided part of the lip-face plate on top of the pin
stem_inset     = 2.0;   // Stem is this much smaller than the plate on each side.
                        // The step between them is a 45 deg chamfer (prints without
                        // supports and self-centres the pin in its seat).
stem_hole_chamfer = 0.5; // Lead-in chamfer at the bottom of the stem hole (absorbs elephant's foot)

cross_pin_dia       = 2.0;  // MEASURE your dowel (cocktail stick / wire) and set this
cross_pin_clearance = 0.2;  // Diametral clearance for the dowel
cross_pin_z         = 2.5;  // Height of dowel centre above the base underside
// Moves the hole in the pin DOWN relative to the hole in the base. A small positive
// value (e.g. 0.1) makes the dowel press the pin down onto its ledge (good with a
// slightly compressible wooden stick). 0 = holes line up exactly.
cross_pin_preload   = 0.0;

/* [Print helpers - base underside] */
// R1 test print: the grids FAILED on both base and lid - the full cross-section above
// the grid (at groove_d) was only held by the island tops and tore off. Off by default.
bottom_grooves   = false; // Cross-hatch of grooves on the base underside: smaller solid
                         // area in the first layers, resin escapes sideways, easier
                         // to get off the build plate
groove_w         = 1.0;
groove_d         = 1.0;  // ~ burn-in + transition layers at 50 um
groove_pitch     = 3.5;
groove_keepout_margin = 0.5; // Min solid land between a hole and the nearest groove

// Drain channels on the base underside: run from the stem hole out to the front and
// back faces, so the stem hole is never a pocket sealed against the build plate
// (suction cup). The cross-dowel hole also vents it, a few mm up.
drain_channels  = true;
drain_w         = 2.0;
drain_d         = 1.0;
bottom_chamfer   = 0.5;  // 45 deg chamfer round the bottom outside edge (hides elephant's foot)

/* [Print helpers - lid top face] */
lid_grooves      = false; // Same groove grid on the lid's top face (see R1 note above)
lid_groove_d     = 1.0;
lid_top_chamfer  = 0.5;
// Pin sockets right through the lid, so they're never blind pockets (suction cups)
// whichever way up the lid is printed.
pin_sockets_through = true;
// Drain channels on the lid's TOP face (build-plate side): a short channel from every
// hole that reaches that face (sprue funnel, vents, pin sockets) out to the nearest
// side edge. Needed if the lid is printed flat on the plate; harmless on supports.
lid_drain_channels = true;
lid_drain_w = 2.0;   // wide/deep enough that over-exposed burn-in layers can't close them
lid_drain_d = 1.0;  // 45 deg chamfer round the lid's top outside edge (build-plate side)

/* [Label] */
label_text  = "R2";      // Debossed on the front (-Y) face of the base - bump per revision
label_size  = 5;         // Cap height-ish, mm
label_depth = 0.6;
label_font  = "Liberation Sans:style=Bold";

pry_slot_w = 10;
pry_slot_d = 1.5;

explode = 25;

/* [Print layout] */
// show = "print": base, lid and core laid out on the build plate in print orientation
// (base upright, lid TOP-FACE-DOWN, core upright). Export it as one STL for the slicer:
//   openscad -D 'show="print"' -o plate.stl mould.scad
print_gap = 10;          // gap between parts on the plate
// Overlay suction cups found by cupcheck.py (red). Generate the file first:
//   python3 cupcheck.py plate.stl --stl-out cups.stl
// OpenSCAD can't do this check itself: booleans can't tell a sealed pocket from one
// that connects to open resin. Stale if the model has changed since cups.stl was made.
show_cups = false;
cups_file = "cups.stl";

/* [Hidden] */
$fn = 48;
eps = 0.01;

w = outer_width  + tolerance;
l = outer_length + tolerance;
h = outer_height + tolerance;
total_h = h + lip_height;

pitch_x = w + cavity_gap;
pitch_y = l + cavity_gap;
box_w = cols * w + (cols - 1) * cavity_gap + 2 * mold_thickness;
box_l = rows * l + (rows - 1) * cavity_gap + 2 * mold_thickness;  // was "w" in v1
floor_t = mold_thickness;
base_h  = floor_t + total_h;

shaft_only_length = ball_shaft_length - ball_height;
ledge_z = floor_t - plate_t - stem_inset;   // z where the 45 deg seat chamfer starts (on the pin)
// The seat cone in the base is the SAME cone as on the pin (zero clearance), so the
// pin bottoms out with its top exactly flush with the cavity floor. Clearance is only
// on the vertical walls. Carried down at 45 deg, the cone meets the looser stem hole
// this far above ledge_z:
seat_bottom_z = ledge_z + stem_clearance;
funnel_w = lip_width  * detent_lip_scale;
funnel_l = lip_length * detent_lip_scale;

// ---- Diagnostics (printed in the console) ----
function draft_deg(size, height) = atan((size * (1 - draft_scale) / 2) / height);
echo(str("Draft per side - body W: ", draft_deg(w, h), " deg, body L: ", draft_deg(l, h),
         " deg, lip W: ", draft_deg(lip_width, lip_height), " deg, lip L: ", draft_deg(lip_length, lip_height), " deg"));
echo(str("Rubber rim at lip face (W, L): ",
         (lip_width  * draft_scale - (funnel_w + 2 * ball_spacing)) / 2, " mm, ",
         (lip_length * draft_scale - (funnel_l + 2 * ball_spacing)) / 2, " mm"));
echo(str("Stem above dowel hole to start of chamfer: ", ledge_z - cross_pin_z - (cross_pin_dia + cross_pin_clearance)/2,
         " mm, stem below dowel hole: ", cross_pin_z - cross_pin_preload - (cross_pin_dia + cross_pin_clearance)/2, " mm"));
if (!pin_sockets_through) {
    echo(str("Lid: material between blind pin holes and top face: ",
             lid_thickness - (pin_height + 0.5) - (lid_grooves ? lid_groove_d : 0), " mm"));
    assert(lid_thickness - (pin_height + 0.5) - (lid_grooves ? lid_groove_d : 0) >= 0.4,
           "Lid too thin: top face would break into the blind alignment-pin holes");
}
echo(str("Lid wall between pin socket and outside edge: ",
         pin_inset - (pin_dia + pin_clearance) / 2, " mm (key pin: ",
         pin_inset - (pin_dia + key_pin_extra + pin_clearance) / 2, " mm)"));
// Nearest cavity point to a pin: cavity corner arc centre is (mold_thickness + r) in from both edges
echo(str("Base: gap between key pin and cavity corner: ",
         sqrt(2) * (mold_thickness + body_corner_radius - pin_inset) - body_corner_radius - (pin_dia + key_pin_extra) / 2, " mm"));
echo(str("Rubber floor under stud tip: ", total_h - (ball_shaft_length + ball_spacing), " mm"));
echo(str("Mould footprint: ", box_w, " x ", box_l, " mm, base height ", base_h,
         " mm, lid ", lid_thickness, " mm"));

// ---- Helpers ----
module rrect(x, y, r) {
    offset(r = r) square([x - 2 * r, y - 2 * r], center = true);
}

function cavity_centres() = [
    for (i = [0 : cols - 1], j = [0 : rows - 1])
        [(i - (cols - 1) / 2) * pitch_x, (j - (rows - 1) / 2) * pitch_y]
];

function pin_positions() = [
    [ box_w / 2 - pin_inset,  box_l / 2 - pin_inset],
    [-box_w / 2 + pin_inset,  box_l / 2 - pin_inset],
    [-box_w / 2 + pin_inset, -box_l / 2 + pin_inset],
    [ box_w / 2 - pin_inset, -box_l / 2 + pin_inset]
];
function pin_d(k) = k == 0 ? pin_dia + key_pin_extra : pin_dia;

// Cross-hatch grid of grooves cut UP from z=0 to z=depth, open at all four edges.
// Groove centre-lines sit on multiples of groove_pitch.
// keepouts = list of [cx, cy, hx, hy]: a hole centred at (cx, cy) with half-extents
// hx, hy. No groove is cut inside the grid block(s) that contain the hole plus
// groove_keepout_margin, so each hole sits in one whole block - no slivers.
module groove_grid(sx, sy, depth, keepouts = []) {
    difference() {
        union() {
            for (x = [-floor(sx / 2 / groove_pitch) * groove_pitch : groove_pitch : sx / 2])
                translate([x - groove_w / 2, -sy / 2 - 1, -1]) cube([groove_w, sy + 2, depth + 1]);
            for (y = [-floor(sy / 2 / groove_pitch) * groove_pitch : groove_pitch : sy / 2])
                translate([-sx / 2 - 1, y - groove_w / 2, -1]) cube([sx + 2, groove_w, depth + 1]);
        }
        for (k = keepouts) {
            m  = groove_keepout_margin;
            x0 = floor((k[0] - k[2] - m) / groove_pitch) * groove_pitch + groove_w / 2;
            x1 = ceil ((k[0] + k[2] + m) / groove_pitch) * groove_pitch - groove_w / 2;
            y0 = floor((k[1] - k[3] - m) / groove_pitch) * groove_pitch + groove_w / 2;
            y1 = ceil ((k[1] + k[3] + m) / groove_pitch) * groove_pitch - groove_w / 2;
            translate([x0, y0, -2]) cube([x1 - x0, y1 - y0, depth + 3]);
        }
    }
}

// Box centred in X/Y, z from 0 to ht, with a 45 deg chamfer c round the z=0 edge
module chamfered_box(sx, sy, ht, c) {
    hull() {
        translate([-sx / 2 + c, -sy / 2 + c, 0]) cube([sx - 2 * c, sy - 2 * c, eps]);
        translate([-sx / 2, -sy / 2, c]) cube([sx, sy, ht - c]);
    }
}

// ---- Part geometry (part's own frame: base face at z=0, lip face at z=total_h) ----
module part_positive() {
    linear_extrude(height = h, scale = draft_scale)
        rrect(w, l, body_corner_radius);
    translate([0, 0, h])
        linear_extrude(height = lip_height, scale = draft_scale)
            rrect(lip_width, lip_length, lip_corner_radius);
}

// Stud-shaped hole. z=0 at the lip face, +z goes into the part.
// pad inflates every radius (and the tip) by that amount.
module ball_positive(pad = 0) {
    // 1. Lead-in funnel
    linear_extrude(height = detent_height, scale = detent_top_scale)
        offset(r = pad) rrect(funnel_w, funnel_l, detent_corner_radius);

    // 2. Collar
    cylinder(h = lip_height, d = ball_shaft_diameter * collar_dia_scale + 2 * pad);

    // 3. Neck
    cylinder(h = shaft_only_length + eps, d = ball_shaft_diameter + 2 * pad);

    // 4. Mushroom head
    translate([0, 0, shaft_only_length])
        rotate_extrude($fn = 80) {
            r_s = ball_shaft_diameter / 2 + pad;
            r_m = ball_dia / 2;
            hh  = ball_height;
            polygon(points = [
                [0, 0],
                [r_s, 0],
                [r_m * 0.80 + pad, hh * 0.05],
                [r_m * 0.95 + pad, hh * 0.10],
                [r_m        + pad, hh * 0.20],   // widest point (= ball_dia)
                [r_m * 0.97 + pad, hh * 0.30],
                [r_m * 0.85 + pad, hh * 0.50],
                [r_m * 0.70 + pad, hh * 0.70],
                [r_m * 0.40 + pad, hh * 0.88],
                [r_m * 0.15 + pad, hh * 0.97],
                [0,                hh + pad]     // tip
            ]);
        }
}

// The finished rubber part (preview / check)
module part() {
    difference() {
        part_positive();
        translate([0, 0, total_h + eps]) mirror([0, 0, 1]) ball_positive(ball_spacing);
    }
}

// ---- Mould ----
// Outline of the lip face (the narrow end of the lip pocket, on the cavity floor)
module lip_face_shape() {
    scale([draft_scale, draft_scale]) rrect(lip_width, lip_length, lip_corner_radius);
}
module stem_shape() {
    offset(delta = -stem_inset) lip_face_shape();
}
// 45 deg transition from stem outline (at z0) to plate outline (at z0 + stem_inset),
// with an extra outward offset c on both (for clearance in the base).
module seat_chamfer(z0, c = 0) {
    hull() {
        translate([0, 0, z0]) linear_extrude(height = eps) offset(delta = c) stem_shape();
        translate([0, 0, z0 + stem_inset - eps]) linear_extrude(height = eps) offset(delta = c) lip_face_shape();
    }
}

// Ejector core pin, in the BASE frame of one cavity: z=floor_t is the cavity
// floor, z=0 is the underside of the base.
module core_pin() {
    color("Orange")
    difference() {
        union() {
            translate([0, 0, floor_t - eps]) ball_positive(ball_spacing);
            translate([0, 0, floor_t - plate_t])
                linear_extrude(height = plate_t) lip_face_shape();
            seat_chamfer(ledge_z);
            linear_extrude(height = ledge_z + eps) stem_shape();
        }
        // Cross-dowel hole (along X)
        translate([0, 0, cross_pin_z - cross_pin_preload]) rotate([0, 90, 0])
            cylinder(h = box_w + 2, d = cross_pin_dia + cross_pin_clearance, center = true, $fn = 24);
    }
}

// Cavity for one part, lip down, lip face on the floor. Extended 1 mm above the
// top so the cut is clean.
module cavity() {
    translate([0, 0, floor_t + total_h]) mirror([0, 0, 1]) {
        part_positive();
        translate([0, 0, -1]) linear_extrude(height = 1 + eps) rrect(w, l, body_corner_radius);
        // Lip pocket grown by core_clearance so its bottom edge lines up exactly with
        // the plate pocket below (no ledge for the ejector plate to catch on).
        // Dividing by draft_scale makes the growth exactly core_clearance at the floor.
        if (!integral_cores)
            translate([0, 0, h])
                linear_extrude(height = lip_height + eps, scale = draft_scale)
                    offset(delta = core_clearance / draft_scale)
                        rrect(lip_width, lip_length, lip_corner_radius);
    }
}

module base() {
    color("SteelBlue")
    difference() {
        // Outer block with a chamfered bottom edge
        chamfered_box(box_w, box_l, base_h, bottom_chamfer);

        // Underside grooves, open at all four edges
        if (bottom_grooves)
            groove_grid(box_w, box_l, groove_d, integral_cores ? [] : [
                for (c = cavity_centres()) [c[0], c[1],
                    (lip_width  * draft_scale) / 2 - stem_inset + stem_clearance + stem_hole_chamfer,
                    (lip_length * draft_scale) / 2 - stem_inset + stem_clearance + stem_hole_chamfer]
            ]);

        // Drain channels from each stem hole to the front and back faces
        if (drain_channels && !integral_cores)
            for (c = cavity_centres())
                translate([c[0] - drain_w / 2, -box_l / 2 - 1, -1])
                    cube([drain_w, box_l + 2, drain_d + 1]);

        // Revision label, debossed into the front (-Y) face, centred on the
        // solid band between the grooves and the pry slot
        if (label_text != "")
            translate([0, -box_l / 2 - eps, (groove_d + base_h - 2) / 2])
                rotate([90, 0, 0]) mirror([0, 0, 1])
                    linear_extrude(height = label_depth + eps)
                        text(label_text, size = label_size, font = label_font,
                             halign = "center", valign = "center");

        for (c = cavity_centres()) translate(c) {
            cavity();
            if (!integral_cores) {
                // Plate pocket ...
                translate([0, 0, floor_t - plate_t - eps])
                    linear_extrude(height = plate_t + 2 * eps) offset(delta = core_clearance) lip_face_shape();
                // ... 45 deg seat: same cone as the pin, ending where it meets the
                // looser stem hole (no step there) ...
                hull() {
                    translate([0, 0, seat_bottom_z]) linear_extrude(height = eps)
                        offset(delta = stem_clearance) stem_shape();
                    translate([0, 0, ledge_z + stem_inset - eps]) linear_extrude(height = eps)
                        lip_face_shape();
                }
                // ... stem hole through to the underside ...
                translate([0, 0, -1])
                    linear_extrude(height = seat_bottom_z + 1 + eps) offset(delta = stem_clearance) stem_shape();
                // ... with a lead-in chamfer at the bottom
                hull() {
                    translate([0, 0, -1]) linear_extrude(height = 1)
                        offset(delta = stem_clearance + stem_hole_chamfer) stem_shape();
                    translate([0, 0, stem_hole_chamfer]) linear_extrude(height = eps)
                        offset(delta = stem_clearance) stem_shape();
                }
                // Cross-dowel hole through the whole base
                translate([0, 0, cross_pin_z]) rotate([0, 90, 0])
                    cylinder(h = box_w + 2, d = cross_pin_dia + cross_pin_clearance, center = true, $fn = 24);
            }
        }

        // Pry slots on the two short ends, at the parting line
        for (s = [-1, 1])
            translate([-pry_slot_w / 2, s * box_l / 2 - (s > 0 ? pry_slot_d : 1), base_h - 2])
                cube([pry_slot_w, pry_slot_d + 1, 3]);
    }

    // Alignment pins (chamfered tips)
    for (k = [0 : 3]) translate([pin_positions()[k][0], pin_positions()[k][1], base_h - eps]) {
        cylinder(h = pin_height - 0.6, d = pin_d(k));
        translate([0, 0, pin_height - 0.6]) cylinder(h = 0.6, d1 = pin_d(k), d2 = pin_d(k) - 1.2);
    }

    if (integral_cores)
        for (c = cavity_centres()) translate(c)
            translate([0, 0, floor_t - eps]) ball_positive(ball_spacing);
}

// Lid, in its own frame: underside (mould face) at z=0.
module lid() {
    color("Gainsboro")
    difference() {
        // Plate with a chamfered TOP edge (top face goes on the build plate)
        translate([0, 0, lid_thickness]) mirror([0, 0, 1])
            chamfered_box(box_w, box_l, lid_thickness, lid_top_chamfer);

        // Top-face grooves (build-plate side)
        if (lid_grooves)
            translate([0, 0, lid_thickness]) mirror([0, 0, 1])
                groove_grid(box_w, box_l, lid_groove_d, concat(
                    [for (c = cavity_centres()) [c[0], c[1], sprue_funnel_dia / 2, sprue_funnel_dia / 2]],
                    [for (c = cavity_centres(), s = [-1, 1])
                        let(r = vent_dia / 2 + vent_countersink)
                        [c[0] + s * (w / 2 - vent_inset), c[1] + s * (l / 2 - vent_inset), r, r]]
                ));

        for (c = cavity_centres()) translate(c) {
            // Sprue + 45 deg pour funnel
            translate([0, 0, -1]) cylinder(h = lid_thickness + 2, d = sprue_dia);
            fh = (sprue_funnel_dia - sprue_dia) / 2;
            translate([0, 0, lid_thickness - fh]) cylinder(h = fh + eps, d1 = sprue_dia, d2 = sprue_funnel_dia);
            // Vents at two diagonal corners
            for (s = [-1, 1])
                translate([s * (w / 2 - vent_inset), s * (l / 2 - vent_inset), -1])
                    cylinder(h = lid_thickness + 2, d = vent_dia);
            if (vent_countersink > 0)
                for (s = [-1, 1])
                    translate([s * (w / 2 - vent_inset), s * (l / 2 - vent_inset), lid_thickness - vent_countersink])
                        cylinder(h = vent_countersink + eps, d1 = vent_dia, d2 = vent_dia + 2 * vent_countersink);
        }

        for (k = [0 : 3]) translate([pin_positions()[k][0], pin_positions()[k][1], -1])
            cylinder(h = pin_sockets_through ? lid_thickness + 2 : pin_height + 1.5,
                     d = pin_d(k) + pin_clearance);

        // Drain channels on the top face: hole centre -> nearest side (+/-X) edge
        if (lid_drain_channels) {
            holes = concat(
                [for (c = cavity_centres()) [c[0], c[1]]],
                [for (c = cavity_centres(), s = [-1, 1]) [c[0] + s * (w / 2 - vent_inset), c[1] + s * (l / 2 - vent_inset)]],
                pin_sockets_through ? pin_positions() : []
            );
            for (hc = holes) {
                dir = hc[0] >= 0 ? 1 : -1;
                x0  = dir > 0 ? hc[0] : -box_w / 2 - 1;
                x1  = dir > 0 ?  box_w / 2 + 1 : hc[0];
                translate([x0, hc[1] - lid_drain_w / 2, lid_thickness - lid_drain_d])
                    cube([x1 - x0, lid_drain_w, lid_drain_d + 1]);
            }
        }
    }
}

module all_cores() {
    for (c = cavity_centres()) translate(c) core_pin();
}

module assembly(gap = 0) {
    color("SteelBlue", 0.9) base();
    if (!integral_cores) {
        color("Orange") translate([0, 0, -gap]) all_cores();
        // Cross dowel(s), one per row
        for (c = cavity_centres()) if (c[0] == cavity_centres()[0][0])
            color("Tan") translate([-gap, c[1], cross_pin_z - gap]) rotate([0, 90, 0])
                cylinder(h = box_w + 10, d = cross_pin_dia, center = true, $fn = 24);
    }
    color("Gainsboro", 0.6) translate([0, 0, base_h + gap]) lid();
    if (with_rubber)
    if (gap > 0)
        for (c = cavity_centres()) translate([c[0], c[1], base_h + lid_thickness + 2 * gap])
            color("DimGray") part();
}

module cut() {   // keep the half with y <= 0
    translate([-box_w, -box_l, -50]) cube([2 * box_w, box_l, 200]);
}

// All three printable parts, oriented and spaced for the build plate (z=0 = plate)
module print_layout() {
    core_w = lip_width * draft_scale;
    span   = box_w + print_gap + box_w + print_gap + core_w;
    x0     = -span / 2;
    translate([x0 + box_w / 2, 0, 0]) base();
    // Lid flipped by ROTATING 180 deg about X (a mirror would make the left-handed twin)
    translate([x0 + box_w + print_gap + box_w / 2, 0, lid_thickness]) rotate([180, 0, 0]) lid();
    if (!integral_cores)
        for (i = [0 : len(cavity_centres()) - 1])
            translate([x0 + 2 * box_w + 2 * print_gap + core_w / 2, i * (lip_length * draft_scale + print_gap), 0])
                core_pin();
}

// ---- Output ----
if (show == "part")          part();
else if (show == "base")     base();
else if (show == "lid")      lid();
else if (show == "core")     core_pin();
else if (show == "cores")    all_cores();
else if (show == "assembly") assembly(0);
else if (show == "exploded") assembly(explode);
else if (show == "print") {
    print_layout();
    if (show_cups) color("Red") import(cups_file);
}
else if (show == "section") {
    color("SteelBlue")  render() intersection() { base(); cut(); }
    color("Orange")     render() intersection() { core_pin(); cut(); }
    color("Gainsboro")  render() intersection() { translate([0, 0, base_h]) lid(); cut(); }
    color("Tan")        render() intersection() {
        translate([0, 0, cross_pin_z]) rotate([0, 90, 0]) cylinder(h = box_w + 10, d = cross_pin_dia, center = true, $fn = 24);
        cut();
    }
    if (with_rubber)
        color("DimGray") render() intersection() {
            translate([0, 0, floor_t + total_h]) mirror([0, 0, 1]) part();
            cut();
        }
}
