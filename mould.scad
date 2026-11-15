// Parametric 2-Part Injection Mold for Door Catch Insert
// Units: millimeters

/* [Parameters] */
// Part dimensions
outer_width = 18.5;      // Base width of the rubber part
outer_length = 23.0;      // Base length of the rubber part
outer_height = 9.5;     // Height of the rubber part, not including lip

draft_angle = 0.95; // TWEAK: Ends up about 1mm smaller w/h at the top
corner_radius = 1.5;  // Configurable corner radius

lip_width = 12.5;        // Width of the upper locating lip
lip_length = 14.5;        // Length of the upper locating lip
lip_height = 4.0;        // Height of the upper locating lip

ball_dia = 8.2;          // Diameter of the ball
ball_height = 6.0;       // Height of the ball

ball_shaft_length = 11;       // TWEAK: length of the stud
ball_shaft_diameter = 5.0;       // diameter of the stud shaft

ball_spacing = 0.2;       // TWEAK: padding for the mould

// Mold box & tolerances
tolerance = 0.15;        // Shrinkage/fit clearance tolerance
mold_thickness = 8.0;    // Wall thickness around the part cavity
pin_dia = 4.0;           // Alignment dowel pin diameter
sprue_dia = 3.5;         // Injection sprue diameter

/* [Calculated Variables] */
w = outer_width + tolerance;
l = outer_length + tolerance;
h = outer_height + tolerance;
box_w = w + (mold_thickness * 2);
box_l = w + (mold_thickness * 2);
box_h = (h / 2) + mold_thickness;

// Increase $fn to make the curved corners smooth (try 32 or 64)
$fn = 32;

module part_positive() {
    // Main square base
    translate([0, 0, 0])
        linear_extrude(height = h, scale = draft_angle) {
            offset(r = corner_radius) {
                square([w - (2 * corner_radius), l - (2 * corner_radius)], center=true);
            }
        }

    // Upper locating lip
    translate([0, 0, h])
        linear_extrude(height = lip_height, scale = draft_angle) {
            offset(r = corner_radius) {
                square([lip_width - (2 * corner_radius), lip_length - (2 * corner_radius)], center=true);
            }
        }
}


module ball_positive() {
    detent_height = lip_height * 0.9;
    detent_top_scale = 0.35;
    detent_lip_scale = 0.8;
    detent_corner_radius = 2;
    
    // 1. Detent funnel in the base lip
    translate([0, 0, 0]) {
        linear_extrude(height = detent_height, scale = detent_top_scale) {
            offset(r = detent_corner_radius) {
                square([lip_width * detent_lip_scale - (2 * detent_corner_radius), lip_length * detent_lip_scale - (2 * detent_corner_radius)], center=true);
            }
        }
    }
    
    shaft_only_length = ball_shaft_length - ball_height;
    
    // 2.5 detent collar
    translate([0, 0, lip_height/2]) {
        cylinder(h = lip_height, d = ball_shaft_diameter * 1.2, center = true);
    }
    
    // 2. Vertical shaft
    translate([0, 0, shaft_only_length / 2]) {
        cylinder(h = shaft_only_length, d = ball_shaft_diameter, center = true);
    }
    
    // 3. Smooth Mushroom Head using multi-point curve approximation
    translate([0, 0, shaft_only_length]) {
        // Higher $fn and smooth polygon curve points
        rotate_extrude($fn = 80) {
            // We use a series of smooth radial points from shaft to max width (ball_dia/2) to apex
            r_shaft = ball_shaft_diameter / 2;
            r_max = ball_dia / 2;
            h_head = ball_height;
            
            polygon(points=[
                [0, 0],
                [r_shaft, 0],
                // Smooth transition points sweeping up to max diameter and doming over
                [r_max * 0.8, h_head * 0.05],
                [r_max*0.95,   h_head * 0.1],
                [r_max,   h_head * 0.2],
                [r_max*0.97,   h_head * 0.3],
                [r_max * 0.85,         h_head * 0.5], // Widest point matching ball_dia
                [r_max * 0.7,  h_head * 0.7],
                [r_max * 0.4,   h_head * 0.88],
                [r_max * 0.15,   h_head * 0.97],
                [0,             h_head]        // Apex at top center
            ]);
        }
    }
}

module part() {
    difference() {
        part_positive();
        
        translate([0, 0, h + lip_height])
        rotate([180, 0, 0]) // Flip top half for view
            ball_positive();
    }
}

part();
