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
//     stem that runs to the underside of the base. The step between plate and stem
//     sits on a ledge, so the pin cannot drop, but it can be pushed UP.
//     A cross-dowel (cocktail stick / wire / printed pin) through the side of the
//     base and the stem stops the pin floating while the rubber cures.
//     To demould: lift the lid, pull the dowel, push the stem up from below - the
//     part rises out of the cavity sitting on the pin - then peel it off by hand.
//   - LID: one sprue (with funnel) + two vents per cavity, plus alignment pins.
//     Either pour through the sprues, or overfill the open cavities and press the
//     lid down so the excess bleeds out of the holes.

/* [What to render] */
show = "assembly"; // [part, base, lid, core, cores, assembly, exploded, section]

/* [Part dimensions] */
outer_width  = 18.5;   // Base width of the rubber part
outer_length = 23.0;   // Base length of the rubber part
outer_height = 9.5;    // Height of the rubber part, not including lip

// NOTE: this is a linear_extrude SCALE factor, not an angle (0.95 = top is 95% of base)
draft_scale   = 0.95;
corner_radius = 1.5;

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
lid_thickness  = 5.0;

pin_dia        = 4.0;   // Alignment pin diameter
key_pin_extra  = 1.0;   // One pin is this much bigger so the lid only fits one way
pin_height     = 4.0;
pin_clearance  = 0.2;   // Diametral clearance in lid holes

sprue_dia        = 3.5;
sprue_funnel_dia = 8.0;
vent_dia         = 1.5;
vent_inset       = 2.5; // Vent distance in from cavity edge

integral_cores = false; // true = cores printed as part of the base (no pins)
core_clearance = 0.08;  // Radial clearance of the pin in its hole in the base
plate_t        = 3.0;   // Thickness of the lip-face plate on top of the pin
stem_inset     = 2.0;   // Stem is this much smaller than the plate on each side (= ledge width)

cross_pin_dia       = 2.0;  // MEASURE your dowel (cocktail stick / wire) and set this
cross_pin_clearance = 0.2;  // Diametral clearance for the dowel
cross_pin_z         = 2.5;  // Height of dowel centre above the base underside
// Moves the hole in the pin DOWN relative to the hole in the base. A small positive
// value (e.g. 0.1) makes the dowel press the pin down onto its ledge (good with a
// slightly compressible wooden stick). 0 = holes line up exactly.
cross_pin_preload   = 0.0;

pry_slot_w = 10;
pry_slot_d = 1.5;

explode = 25;

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
funnel_w = lip_width  * detent_lip_scale;
funnel_l = lip_length * detent_lip_scale;

// ---- Diagnostics (printed in the console) ----
function draft_deg(size, height) = atan((size * (1 - draft_scale) / 2) / height);
echo(str("Draft per side - body W: ", draft_deg(w, h), " deg, body L: ", draft_deg(l, h),
         " deg, lip W: ", draft_deg(lip_width, lip_height), " deg, lip L: ", draft_deg(lip_length, lip_height), " deg"));
echo(str("Rubber rim at lip face (W, L): ",
         (lip_width  * draft_scale - (funnel_w + 2 * ball_spacing)) / 2, " mm, ",
         (lip_length * draft_scale - (funnel_l + 2 * ball_spacing)) / 2, " mm"));
echo(str("Pin ledge width: ", stem_inset, " mm, wall left above/below dowel in stem: ", floor_t - plate_t - cross_pin_z - (cross_pin_dia + cross_pin_clearance)/2, " / ", cross_pin_z - cross_pin_preload - (cross_pin_dia + cross_pin_clearance)/2, " mm"));
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
    [ box_w / 2 - mold_thickness / 2,  box_l / 2 - mold_thickness / 2],
    [-box_w / 2 + mold_thickness / 2,  box_l / 2 - mold_thickness / 2],
    [-box_w / 2 + mold_thickness / 2, -box_l / 2 + mold_thickness / 2],
    [ box_w / 2 - mold_thickness / 2, -box_l / 2 + mold_thickness / 2]
];
function pin_d(k) = k == 0 ? pin_dia + key_pin_extra : pin_dia;

// ---- Part geometry (part's own frame: base face at z=0, lip face at z=total_h) ----
module part_positive() {
    linear_extrude(height = h, scale = draft_scale)
        rrect(w, l, corner_radius);
    translate([0, 0, h])
        linear_extrude(height = lip_height, scale = draft_scale)
            rrect(lip_width, lip_length, corner_radius);
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
    scale([draft_scale, draft_scale]) rrect(lip_width, lip_length, corner_radius);
}
module stem_shape() {
    offset(delta = -stem_inset) lip_face_shape();
}

// Ejector core pin, in the BASE frame of one cavity: z=floor_t is the cavity
// floor, z=0 is the underside of the base.
module core_pin() {
    difference() {
        union() {
            translate([0, 0, floor_t - eps]) ball_positive(ball_spacing);
            translate([0, 0, floor_t - plate_t])
                linear_extrude(height = plate_t) lip_face_shape();
            linear_extrude(height = floor_t - plate_t + eps) stem_shape();
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
        translate([0, 0, -1]) linear_extrude(height = 1 + eps) rrect(w, l, corner_radius);
    }
}

module base() {
    difference() {
        translate([-box_w / 2, -box_l / 2, 0]) cube([box_w, box_l, base_h]);

        for (c = cavity_centres()) translate(c) {
            cavity();
            if (!integral_cores) {
                // Plate pocket (with the ledge at its bottom) ...
                translate([0, 0, floor_t - plate_t])
                    linear_extrude(height = plate_t + eps) offset(delta = core_clearance) lip_face_shape();
                // ... and stem hole through to the underside
                translate([0, 0, -1])
                    linear_extrude(height = floor_t - plate_t + 1 + eps) offset(delta = core_clearance) stem_shape();
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
    difference() {
        translate([-box_w / 2, -box_l / 2, 0]) cube([box_w, box_l, lid_thickness]);

        for (c = cavity_centres()) translate(c) {
            // Sprue + 45 deg pour funnel
            translate([0, 0, -1]) cylinder(h = lid_thickness + 2, d = sprue_dia);
            fh = (sprue_funnel_dia - sprue_dia) / 2;
            translate([0, 0, lid_thickness - fh]) cylinder(h = fh + eps, d1 = sprue_dia, d2 = sprue_funnel_dia);
            // Vents at two diagonal corners
            for (s = [-1, 1])
                translate([s * (w / 2 - vent_inset), s * (l / 2 - vent_inset), -1])
                    cylinder(h = lid_thickness + 2, d = vent_dia);
        }

        for (k = [0 : 3]) translate([pin_positions()[k][0], pin_positions()[k][1], -1])
            cylinder(h = pin_height + 1.5, d = pin_d(k) + pin_clearance);
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
    color("LightGrey", 0.6) translate([0, 0, base_h + gap]) lid();
    if (gap > 0)
        for (c = cavity_centres()) translate([c[0], c[1], base_h + lid_thickness + 2 * gap])
            color("DimGray") part();
}

// ---- Output ----
if (show == "part")          part();
else if (show == "base")     base();
else if (show == "lid")      lid();
else if (show == "core")     core_pin();
else if (show == "cores")    all_cores();
else if (show == "assembly") assembly(0);
else if (show == "exploded") assembly(explode);
else if (show == "section")
    difference() {
        assembly(0);
        translate([-box_w, cavity_centres()[0][1], -50]) cube([2 * box_w, box_l, 200]);
    }
