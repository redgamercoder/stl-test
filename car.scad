// ============================================================
//  Smooth sports car  —  OpenSCAD
//  Body = chain of pairwise-hulled ellipsoids ("skinning"),
//  belly flat-cut, real wheel arches, rounded detailing.
//
//  Coordinate system:  X = width, Y = length (+front), Z = up
//  Render STL:  openscad -o car.stl car.scad
// ============================================================

$fn = 64;

FLOOR     = 2.6;   // belly cut height (ground clearance)
WHEEL_R   = 4.0;   // tyre radius
TRACK     = 8.0;   // wheel centre offset in X
AX_F      = 12.0;  // front axle Y
AX_R      = -12.0; // rear  axle Y

// ---------- helpers ----------------------------------------
module ellipsoid(hw, ry, hh) scale([hw, ry, hh]) sphere(r = 1);

// Skin a list of stations [y, half_width, z_centre, half_height]
module skin(st, ry = 1.7) {
    for (i = [0 : len(st) - 2]) hull() {
        translate([0, st[i][0],     st[i][2]])     ellipsoid(st[i][1],     ry, st[i][3]);
        translate([0, st[i + 1][0], st[i + 1][2]]) ellipsoid(st[i + 1][1], ry, st[i + 1][3]);
    }
}

// ---------- body & greenhouse stations ---------------------
body = [
//   y      hw    zc    hh
    [-20.0, 7.0,  5.2, 2.1],   // tail
    [-17.0, 8.2,  5.4, 2.6],
    [-13.0, 8.8,  5.4, 2.9],   // rear haunch
    [ -8.0, 8.7,  5.2, 2.9],
    [ -2.0, 8.7,  5.0, 2.8],   // doors
    [  4.0, 8.7,  4.7, 2.6],   // cowl
    [  9.0, 8.9,  4.4, 2.3],   // front haunch
    [ 13.0, 8.4,  4.2, 2.0],   // hood
    [ 16.0, 7.6,  4.1, 1.8],
    [ 18.5, 6.5,  4.2, 1.6],   // nose
    [ 20.2, 5.2,  4.3, 1.4],   // nose tip
];

// fastback greenhouse: lower roof, faired into the rear deck
cabin = [
//   y      hw    zc    hh
    [  5.0, 5.4, 6.5, 0.4],    // windshield base (blends into cowl)
    [  1.5, 5.8, 7.6, 1.3],    // windshield top
    [ -3.0, 6.0, 7.9, 1.6],    // roof
    [ -9.0, 5.6, 7.2, 1.0],    // fastback slope
    [-14.0, 4.8, 6.1, 0.4],    // fairs into the tail
];

// ---------- wheels -----------------------------------------
module tyre(R = WHEEL_R, W = 3.0, ri = 2.3, cr = 0.55) {
    rotate([0, 90, 0])
        rotate_extrude($fn = 64)
            hull() {
                translate([ri + cr, -W/2 + cr]) circle(cr);
                translate([R  - cr, -W/2 + cr]) circle(cr);
                translate([R  - cr,  W/2 - cr]) circle(cr);
                translate([ri + cr,  W/2 - cr]) circle(cr);
            }
}

module rim(side, W = 3.0, ri = 2.3) {
    xf = side * (W/2 - 0.25);
    // hub
    translate([side * (W/2 + 0.05), 0, 0]) rotate([0, 90, 0])
        cylinder(r = 0.95, h = 0.7, center = true, $fn = 28);
    // outer lip ring
    translate([xf, 0, 0]) rotate([0, 90, 0]) difference() {
        cylinder(r = ri + 0.15, h = 0.45, center = true, $fn = 56);
        cylinder(r = ri - 0.45, h = 1.0,  center = true, $fn = 56);
    }
    // five spokes
    for (a = [0 : 72 : 359])
        translate([xf, 0, 0]) rotate([a, 0, 0])
            translate([0, 0, (ri) / 2 + 0.55])
                cube([0.55, 1.0, ri + 1.0], center = true);
}

module wheel(side, y) {
    translate([side * TRACK, y, WHEEL_R]) {
        tyre();
        rim(side);
    }
}

module wheel_cut(side, y, W = 3.0) {           // arch carved from body
    translate([side * TRACK, y, WHEEL_R])
        rotate([0, 90, 0])
            cylinder(r = WHEEL_R + 0.7, h = W + 2.2, center = true, $fn = 48);
}

// ---------- detail bits ------------------------------------
module rounded_slab(len, wid, thk, r = 0.4) {  // smooth slab along X
    hull() for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * (len/2 - r), sy * (wid/2 - r), 0])
            cylinder(r = r, h = thk, center = true, $fn = 24);
}

module details() {
    // front splitter (tucked under the nose, rounded)
    translate([0, 18.8, FLOOR + 0.1]) rounded_slab(13, 2.6, 0.5, 0.5);
    // rear diffuser
    translate([0, -19.4, FLOOR + 0.15]) rounded_slab(13, 2.2, 0.6, 0.4);

    // headlights (flat, swept lenses)
    for (s = [-1, 1]) translate([s * 5.0, 18.3, 4.9]) rotate([0, 0, -s * 18])
        scale([2.4, 1.1, 0.6]) sphere(1, $fn = 36);
    // tail light bar
    translate([0, -19.9, 5.9]) scale([7.4, 0.5, 0.7]) sphere(1, $fn = 40);

    // twin exhausts
    for (s = [-1, 1]) translate([s * 3.4, -20.9, 3.0]) rotate([90, 0, 0])
        cylinder(r = 0.7, h = 1.4, center = true, $fn = 24);

    // side mirrors (teardrop arm anchored into the body + head)
    for (s = [-1, 1]) {
        hull() {
            translate([s * 6.8, 6.2, 6.7]) sphere(0.4, $fn = 20);
            translate([s * 8.7, 6.6, 7.0]) sphere(0.5, $fn = 20);
        }
        translate([s * 9.0, 6.7, 7.1]) scale([0.55, 1.2, 0.85]) sphere(1, $fn = 24);
    }

    // rear wing
    for (s = [-1, 1]) translate([s * 6.8, -17.6, 7.6])
        cube([0.7, 1.0, 3.0], center = true);
    translate([0, -18.1, 9.2]) rotate([8, 0, 0]) rounded_slab(16, 2.6, 0.55, 0.25);
}

// ---------- assembly ---------------------------------------
module body_solid() {
    difference() {
        union() {
            skin(body, 1.7);
            skin(cabin, 2.0);   // larger blend radius melts cabin into body
        }
        // flat belly
        translate([0, 0, FLOOR - 100]) cube([400, 400, 200], center = true);
        // wheel arches
        wheel_cut( 1, AX_F); wheel_cut(-1, AX_F);
        wheel_cut( 1, AX_R); wheel_cut(-1, AX_R);
    }
}

color([0.20, 0.45, 0.85]) {
    body_solid();
    wheel( 1, AX_F); wheel(-1, AX_F);
    wheel( 1, AX_R); wheel(-1, AX_R);
    details();
}
