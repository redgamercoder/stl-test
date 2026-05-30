// ============================================================
//  Raspberry Pi 5 Desktop Tower Case
//  Mini-tower PC aesthetic.
//
//  Origin: bottom-front-left corner of outer shell.
//  X = width (left→right), Y = depth (front→back), Z = height (bottom→top)
//
//  Printing: upright. Body + side panel are separate objects.
//  Screw together with M3 screws.
// ============================================================

$fn = 48;

// ── Pi 5 board spec (mm) ─────────────────────────────────────
PI_W = 85;    PI_D = 56;    PI_PCB = 1.5;

// M2.5 hole positions from board corner [x along board-width, y along board-depth]
PI_HOLES = [[3.5,3.5],[61.5,3.5],[3.5,52.5],[61.5,52.5]];

MOUNT_SCREW_D = 2.5;    // M2.5 through-hole
MOUNT_OD      = 5.5;    // standoff outer dia
STANDOFF_H    = 6.0;    // standoff height (lifts board off floor)

// ── 40 mm fan ────────────────────────────────────────────────
FAN         = 40;
FAN_HOLE_D  = 3.2;      // M3
FAN_PITCH   = 32;       // hole centres

// ── Case walls ───────────────────────────────────────────────
WALL  = 3.0;
FLOOR = 3.5;
CEIL  = 3.5;

// Inner cavity (Pi + airflow clearance)
IN_W = PI_W + 18;   // 9 mm each side
IN_D = PI_D + 16;   // 8 mm front + rear
IN_H = 120;

OW = IN_W + WALL*2;
OD = IN_D + WALL*2;
OH = IN_H + FLOOR + CEIL;

// Pi board placement inside cavity (centred in X, near back)
PI_XOFF = (IN_W - PI_W) / 2;      // from inner-left wall
PI_YOFF = IN_D - PI_D - 6;        // flush to rear, 6mm air gap at back
// absolute coords of Pi [0,0] corner (bottom-left when looking from top)
PI_AX = WALL + PI_XOFF;
PI_AY = WALL + PI_YOFF;
PI_AZ = FLOOR + STANDOFF_H + PI_PCB;  // top of PCB

// Fan centres on top face (two fans side by side, centred)
FAN1_X = OW/2 - FAN/2 - 3;
FAN2_X = OW/2 + FAN/2 + 3;
FAN_Y  = OD / 2;

// ─────────────────────── helpers ─────────────────────────────

module rounded_box_z(w, d, h, r=4) {
    // box from z=0 to z=h, corners rounded in XY
    hull() for (sx=[-1,1], sy=[-1,1])
        translate([w/2 + sx*(w/2-r), d/2 + sy*(d/2-r), 0])
            cylinder(r=r, h=h, $fn=32);
}

module standoff(ax, ay) {
    // sits on the floor, open M2.5 hole up through it
    translate([ax, ay, FLOOR])
        difference() {
            cylinder(d=MOUNT_OD,      h=STANDOFF_H, $fn=24);
            cylinder(d=MOUNT_SCREW_D, h=STANDOFF_H+0.1, $fn=16);
        }
}

// Fan cutout centred at (cx,cy) cut through thickness t (in XY face, carved in Z)
module fan_cutout_top(cx, cy) {
    translate([cx, cy, OH - CEIL - 0.1]) {
        // spoked grill (leaves material for a grill, fan sits on top)
        difference() {
            cylinder(d=FAN-2, h=CEIL+0.2, $fn=32);
            // grill bars — leave 1.2mm ribs
            for (a=[0,45,90,135])
                rotate([0,0,a])
                    cube([FAN-2, 1.4, CEIL+0.4], center=true);
            // inner ring kept solid for structure — nothing here
        }
        // M3 mounting holes
        for (sx=[-1,1], sy=[-1,1])
            translate([sx*FAN_PITCH/2, sy*FAN_PITCH/2, 0])
                cylinder(d=FAN_HOLE_D, h=CEIL+0.2, $fn=16);
    }
}

// ─────────────────────── front face (Y=0) ────────────────────
module front_details() {
    // ventilation slots — lower-left cluster
    for (i=[0:5])
        translate([WALL+6+i*5, -0.1, FLOOR+8])
            cube([3, WALL+0.2, 20]);

    // power button ring recess then hole
    translate([OW*0.72, -0.1, OH*0.78]) rotate([-90,0,0]) {
        cylinder(d=11, h=WALL+0.2, $fn=32);
        cylinder(d=6.5, h=WALL+0.4, $fn=24);
    }
    // LED hole
    translate([OW*0.72+16, -0.1, OH*0.78]) rotate([-90,0,0])
        cylinder(d=3.2, h=WALL+0.2, $fn=16);

    // front USB-A × 2 (stacked)
    translate([OW*0.55, -0.1, OH*0.52])
        cube([13.5, WALL+0.2, 7]);
    translate([OW*0.55, -0.1, OH*0.52+10])
        cube([13.5, WALL+0.2, 7]);

    // decorative horizontal groove lines
    for (z=[OH*0.36, OH*0.38])
        translate([WALL, -0.1, z])
            cube([OW-WALL*2, WALL*0.4, 1.0]);
}

// ─────────────────────── back face (Y=OD) ────────────────────
// Pi 5 port layout (approx, measured from Pi corner):
//  USB-C power: x≈7,  z≈11  (3.5mm high, 9mm wide)
//  HDMI 0:      x≈27, z≈10  (8mm wide, 6mm high)
//  HDMI 1:      x≈38, z≈10
//  Audio:       x≈53, z≈10  (7mm dia)
//  USB 3 × 2:   x≈61, z≈2   (15mm wide, 16mm high — dual stack)
//  USB 2 × 2:   x≈61, z≈19
//  Ethernet:    x≈74, z≈3   (16mm wide, 14mm high)
//  GPIO:        x≈7,  z≈30  (full 51mm wide, 8mm tall)
module back_details() {
    bx = PI_AX;     // Pi's X origin in world coords
    bz = FLOOR + STANDOFF_H;  // Pi board bottom in world coords

    // USB-C power
    translate([bx+5, OD-WALL-0.1, bz+9])  cube([9, WALL+0.2, 6]);
    // HDMI 0
    translate([bx+25, OD-WALL-0.1, bz+8]) cube([9, WALL+0.2, 7]);
    // HDMI 1
    translate([bx+36, OD-WALL-0.1, bz+8]) cube([9, WALL+0.2, 7]);
    // 3.5mm audio
    translate([bx+52, OD-WALL-0.1, bz+10]) rotate([-90,0,0])
        cylinder(d=7.5, h=WALL+0.2, $fn=20);
    // USB 3.0 × 2 (dual stack)
    translate([bx+59, OD-WALL-0.1, bz+1])  cube([15, WALL+0.2, 17]);
    // USB 2.0 × 2
    translate([bx+59, OD-WALL-0.1, bz+19]) cube([15, WALL+0.2, 17]);
    // Ethernet
    translate([bx+72, OD-WALL-0.1, bz+1])  cube([16, WALL+0.2, 15]);
    // GPIO header slot
    translate([bx+7,  OD-WALL-0.1, bz+28]) cube([51, WALL+0.2, 9]);
}

// ─────────────────────── bottom vents ────────────────────────
module bottom_vents() {
    for (i=[0:4])
        translate([WALL+10+i*16, OD/2-12, -0.1])
            cube([9, 24, FLOOR+0.2]);
}

// ─────────────────────── side panel screw bosses ─────────────
// 4 bosses on left face (X=0 side) for the removable panel
BOSS_POSITIONS = [[OD*0.25, OH*0.25],[OD*0.75, OH*0.25],
                  [OD*0.25, OH*0.75],[OD*0.75, OH*0.75]];
module side_screw_holes_left() {
    for (p=BOSS_POSITIONS)
        translate([-0.1, p[0], p[1]]) rotate([0,90,0])
            cylinder(d=3.0, h=WALL+0.2, $fn=16);
}

// ─────────────────────── case body ───────────────────────────
module case_body() {
    difference() {
        rounded_box_z(OW, OD, OH, 4);
        // hollow
        translate([WALL, WALL, FLOOR]) cube([IN_W, IN_D, IN_H+CEIL+0.1]);
        // top fan cutouts
        fan_cutout_top(FAN1_X, FAN_Y);
        fan_cutout_top(FAN2_X, FAN_Y);
        // front details
        front_details();
        // back I/O
        back_details();
        // bottom vents
        bottom_vents();
        // left side panel screw holes
        side_screw_holes_left();
    }
}

// Pi standoffs (4× M2.5)
module pi_mounts() {
    for (h=PI_HOLES)
        standoff(PI_AX + h[0], PI_AY + h[1]);
}

// ─────────────────────── side panel ──────────────────────────
// Printed separately, screws onto left face.
// Includes a mesh window so you can see inside.
module side_panel() {
    translate([-(WALL+6), 0, 0]) {
        difference() {
            rounded_box_z(WALL, OD-1, OH-1, 3);
            // window opening
            translate([-.1, OD*0.15, OH*0.18])
                cube([WALL+0.2, OD*0.70, OH*0.60]);
            // screw holes
            for (p=BOSS_POSITIONS)
                translate([WALL+0.1, p[0], p[1]]) rotate([0,90,0])
                    cylinder(d=3.2, h=WALL+0.2, $fn=16);
        }
        // window mesh (thin grid stays in panel)
        translate([0, OD*0.15, OH*0.18])
            intersection() {
                cube([WALL*0.4, OD*0.70, OH*0.60]);
                union() {
                    for (i=[0:4])
                        translate([0, i*OD*0.70/4, 0])
                            cube([WALL*0.4, 1.0, OH*0.60]);
                    for (j=[0:5])
                        translate([0, 0, j*OH*0.60/5])
                            cube([WALL*0.4, OD*0.70, 1.0]);
                }
            }
    }
}

// ─────────────────────── render ──────────────────────────────
color([0.15,0.15,0.17]) {
    case_body();
    pi_mounts();
}
color([0.22,0.22,0.25], 0.85)
    side_panel();
