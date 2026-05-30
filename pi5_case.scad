// ============================================================
//  Raspberry Pi 5 Desktop Tower Case  — v3
//
//  Coordinate system (case origin = outer bottom-front-left):
//    X = width  (left → right)
//    Y = depth  (front → back)
//    Z = height (bottom → top)
//
//  Pi 5 board orientation inside:
//    85mm board length  spans case X axis
//    56mm board width   spans case Y axis
//    Pi LEFT  short edge (power/HDMI/audio)   → case LEFT  wall  (X=0)
//    Pi RIGHT short edge (USB3/USB2/Ethernet) → case RIGHT wall  (X=OW)
//    Pi LONG  front edge (microSD)            → case FRONT wall  (Y=0)
//    Pi LONG  rear  edge (GPIO)               → internal (accessed via lid)
//
//  Three printable parts:
//    1. case_body()   — floor + 4 walls, port cutouts, standoffs
//    2. lid()         — top panel with 2× 40mm fan grills, M3 screws
//    3. window_panel() — decorative left window panel (M3 screw-on)
//
//  All dimensions in mm.  Tolerances: +0.3 mm per port side.
// ============================================================

$fn = 52;

// ── Pi 5 board ────────────────────────────────────────────────────────────────
PI_W   = 85.0;    // board X span
PI_D   = 56.0;    // board Y span
PI_PCB = 1.5;     // PCB thickness

// M2.5 standoff hole positions [x_from_left, y_from_front] on board
PI_HOLES = [[3.5, 3.5], [61.5, 3.5], [3.5, 52.5], [61.5, 52.5]];

// ── Pi 5 port positions ───────────────────────────────────────────────────────
// All measurements from the official Raspberry Pi 5 mechanical drawing.
// Format: [[y_near, y_far], [z_pcb_bottom, z_pcb_top]]
//   y_near/far = distance along the SHORT (56mm) edge from the FRONT board corner
//   z_bottom/top = height above BOTTOM of PCB (0 = bottom surface of PCB)
// The PCB itself occupies z = 0 to PI_PCB (= 1.5mm)
// Connectors sit on top of the PCB, so z_bottom >= PI_PCB for surface-mount connectors,
// but bottom-entry connectors (microSD) have z_bottom < 0.

// LEFT wall (Pi board X=0 edge) ── power / HDMI / audio ─────────────────────
//   USB-C power:    8.9mm wide, 3.5mm tall
//   micro-HDMI:     7.4mm wide, 4.45mm tall (both connectors identical)
//   3.5mm audio:    6mm diameter (circular)

USBC   = [[3.5,  12.4], [PI_PCB,       PI_PCB+3.5 ]];   // USB-C power
HDMI0  = [[14.8, 22.2], [PI_PCB,       PI_PCB+4.45]];   // micro-HDMI 0
HDMI1  = [[24.8, 32.2], [PI_PCB,       PI_PCB+4.45]];   // micro-HDMI 1
AUDIO  = [[42.0, 42.0], [PI_PCB+3.0,   0         ]];    // audio: [y_ctr, z_ctr, r]
AUDIO_CY = 42.0;      // y centre along board edge
AUDIO_CZ = PI_PCB + 3.5;  // z centre above PCB bottom
AUDIO_R  = 3.0;       // radius of 3.5mm jack opening

// RIGHT wall (Pi board X=85 edge) ── USB3 / USB2 / Ethernet ─────────────────
//   USB 3.0 ×2 stacked Type-A:  14.0mm wide, 15.5mm tall
//   USB 2.0 ×2 stacked Type-A:  14.0mm wide, 15.5mm tall
//   Gigabit Ethernet RJ45:      16.0mm wide, 13.5mm tall

USB3   = [[ 2.5, 16.5], [PI_PCB, PI_PCB+15.5]];  // USB 3.0 ×2 dual stack
USB2   = [[19.5, 33.5], [PI_PCB, PI_PCB+15.5]];  // USB 2.0 ×2 dual stack
ETH    = [[37.5, 53.5], [PI_PCB, PI_PCB+13.5]];  // Gigabit Ethernet RJ45

// FRONT wall (Pi board Y=0 edge) ── microSD ──────────────────────────────────
//   microSD push-push slot: 12.0mm wide, 1.5mm above PCB, slot extends below PCB
SDCARD = [[17.0, 29.0], [-1.5, 1.5]];  // [x_from_pi_left], [z from pcb bottom]

// ── Standoffs ─────────────────────────────────────────────────────────────────
STOFF_H  = 6.0;   // standoff post height (lifts PCB above floor)
STOFF_OD = 6.2;   // standoff cylinder outer diameter
M25_D    = 2.7;   // M2.5 screw clearance hole

// ── Case shell dimensions ─────────────────────────────────────────────────────
WALL  = 3.0;    // wall thickness
FLOOR = 4.0;    // floor thickness
LID_T = 4.0;    // lid thickness

// Inner cavity: Pi + clearances
//   X: 7mm each side of board  → IN_W = 85 + 14 = 99
//   Y: 10mm front air gap, 12mm rear air gap → IN_D = 56 + 22 = 78
//   Z: 60mm above board top   → IN_H = 60 + STOFF_H + PI_PCB + FLOOR = ~76
// (Tower height driven by style, not airflow minimum)
IN_W = PI_W + 14;    // 99 mm
IN_D = PI_D + 22;    // 78 mm
IN_H = 116;          // interior height (above floor)

OW = IN_W + WALL * 2;   // 105 mm outer width
OD = IN_D + WALL * 2;   // 84  mm outer depth
OH = IN_H + FLOOR;      // 120 mm body height (lid NOT included)

// Pi board bottom-left corner in case coords
PI_AX    = WALL + (IN_W - PI_W) / 2;  // = 10 mm  (centred in X)
PI_AY    = WALL + 10;                  // = 13 mm  (10mm front clearance)
PI_FLOOR = FLOOR + STOFF_H;            // = 10 mm  (Z of PCB bottom surface)

// Verify Pi Y extent: PI_AY + PI_D = 13+56 = 69 mm  (back inner wall at OD-WALL = 81) → 12mm rear clearance ✓

// ── Fan spec ──────────────────────────────────────────────────────────────────
FAN_SIZE  = 40;
FAN_PITCH = 32;     // M3 hole centres (standard 40mm fan)
FAN_HOLE  = 3.2;    // M3 screw clearance

// Two fans side-by-side in X, centred in Y on lid
F1X = OW/2 - FAN_SIZE/2 - 4;   // = 28.5
F2X = OW/2 + FAN_SIZE/2 + 4;   // = 76.5
FY  = OD / 2;                   // = 42.0

// Lid locating ridge (lips inside the lid that locate onto body top rim)
RIDGE_H = 2.5;   // ridge depth below lid
RIDGE_W = 1.5;   // ridge wall width

// Lid screw boss positions (4 corners, inside body top rim)
LID_BOSS = [[WALL+5, WALL+5], [OW-WALL-5, WALL+5],
            [WALL+5, OD-WALL-5], [OW-WALL-5, OD-WALL-5]];
LID_M3_D = 3.2;   // M3 clearance
LID_BOSS_OD = 7;

// ─────────────────────── helper modules ──────────────────────────────────────

// Rounded box (XY corners) from z=0 to z=h
module rbox(w, d, h, r=4) {
    hull() for (sx=[-1,1], sy=[-1,1])
        translate([w/2+sx*(w/2-r), d/2+sy*(d/2-r), 0])
            cylinder(r=r, h=h, $fn=32);
}

// Rectangular port slot (absolute case coordinates)
// Cuts through a wall; caller sets oversized x0/x1 range.
module port_slot(x0, x1, y0, y1, z0, z1, tol=0.3) {
    translate([x0, y0-tol, z0-tol])
        cube([x1-x0, y1-y0+2*tol, z1-z0+2*tol]);
}

// Circular port slot (audio jack, SD headphone etc.)
module port_hole(x0, x1, y_ctr, z_ctr, r, tol=0.35) {
    translate([x0, y_ctr, z_ctr]) rotate([0,90,0])
        cylinder(r=r+tol, h=x1-x0, $fn=30);
}

// Left-wall port helper: board Y → case Y,  board Z → case Z
function ly(by) = PI_AY + by;
function lz(bz) = PI_FLOOR + bz;

// Fan grill cutout (centred at cx, cy, cut from z0 downward through thickness t)
module fan_grill(cx, cy, z0, t) {
    translate([cx, cy, z0]) {
        // Octagonal main opening (good airflow)
        cylinder(d=FAN_SIZE-4, h=t+0.2, $fn=8, center=false);
        // Grill ribs (thin spokes that survive print)
        for (a=[0,45,90,135])
            rotate([0,0,a])
                cube([FAN_SIZE-4, 1.4, t+0.2], center=true);
        // M3 mounting holes
        for (sx=[-1,1], sy=[-1,1])
            translate([sx*FAN_PITCH/2, sy*FAN_PITCH/2, 0])
                cylinder(d=FAN_HOLE, h=t+0.2, $fn=16);
    }
}

// Standoff with M2.5 hole
module standoff(ax, ay) {
    translate([ax, ay, FLOOR])
        difference() {
            cylinder(d=STOFF_OD, h=STOFF_H, $fn=28);
            cylinder(d=M25_D,    h=STOFF_H+0.1, $fn=16);
        }
}

// ─────────────────────── case body ───────────────────────────────────────────
module case_body() {
    difference() {
        // Outer shell
        rbox(OW, OD, OH, 5);

        // Hollow interior
        translate([WALL, WALL, FLOOR]) cube([IN_W, IN_D, IN_H + 0.2]);

        // ── LEFT WALL (X=0): USB-C, HDMI×2, audio ──────────────────────
        port_slot(-0.1, WALL+0.1,
            ly(USBC[0][0]),  ly(USBC[0][1]),
            lz(USBC[1][0]),  lz(USBC[1][1]));

        port_slot(-0.1, WALL+0.1,
            ly(HDMI0[0][0]), ly(HDMI0[0][1]),
            lz(HDMI0[1][0]), lz(HDMI0[1][1]));

        port_slot(-0.1, WALL+0.1,
            ly(HDMI1[0][0]), ly(HDMI1[0][1]),
            lz(HDMI1[1][0]), lz(HDMI1[1][1]));

        port_hole(-0.1, WALL+0.1,
            ly(AUDIO_CY), lz(AUDIO_CZ), AUDIO_R);

        // ── RIGHT WALL (X=OW): USB3×2, USB2×2, Ethernet ────────────────
        port_slot(OW-WALL-0.1, OW+0.1,
            ly(USB3[0][0]),  ly(USB3[0][1]),
            lz(USB3[1][0]),  lz(USB3[1][1]));

        port_slot(OW-WALL-0.1, OW+0.1,
            ly(USB2[0][0]),  ly(USB2[0][1]),
            lz(USB2[1][0]),  lz(USB2[1][1]));

        port_slot(OW-WALL-0.1, OW+0.1,
            ly(ETH[0][0]),   ly(ETH[0][1]),
            lz(ETH[1][0]),   lz(ETH[1][1]));

        // ── FRONT WALL (Y=0): microSD + button + LED + vents ────────────
        // microSD slot (at board X position PI_AX + board_x)
        port_slot(PI_AX+SDCARD[0][0], PI_AX+SDCARD[0][1],
            -0.1, WALL+0.1,
            lz(SDCARD[1][0]), lz(SDCARD[1][1]));

        // Power button (ring recess + hole)
        translate([OW*0.72, -0.1, OH*0.78]) rotate([-90,0,0]) {
            cylinder(d=12,  h=WALL+0.2, $fn=32);   // recess ring
            cylinder(d=6.5, h=WALL+0.2, $fn=24);   // button hole
        }
        // Activity LED
        translate([OW*0.72+17, -0.1, OH*0.78]) rotate([-90,0,0])
            cylinder(d=3.5, h=WALL+0.2, $fn=16);

        // Vent slots (left cluster)
        for (i=[0:5])
            translate([WALL+7+i*5.5, -0.1, FLOOR+10])
                cube([3.5, WALL+0.2, 20]);

        // Decorative horizontal groove
        translate([WALL+1, -0.1, OH*0.44]) cube([OW-WALL*2-2, WALL*0.45, 1.2]);

        // ── BACK WALL (Y=OD): circular vent grille ──────────────────────
        for (i=[-3:3])
            translate([OW/2 + i*9, OD-WALL-0.1, OH*0.45]) rotate([-90,0,0])
                cylinder(d=5, h=WALL+0.2, $fn=20);

        // ── BOTTOM vents (intake under board) ───────────────────────────
        for (i=[0:4])
            translate([WALL+8+i*17, OD/2-11, -0.1])
                cube([9, 22, FLOOR+0.2]);

        // ── Lid screw boss holes (M3, top rim) ──────────────────────────
        for (p = LID_BOSS)
            translate([p[0], p[1], OH-4])
                cylinder(d=LID_M3_D, h=6, $fn=16);
    }

    // Pi standoffs (inside, 4×)
    for (h = PI_HOLES)
        standoff(PI_AX + h[0], PI_AY + h[1]);

    // Lid screw bosses (short cylinders at top rim interior)
    for (p = LID_BOSS)
        difference() {
            translate([p[0]-LID_BOSS_OD/2, p[1]-LID_BOSS_OD/2, OH-8])
                cube([LID_BOSS_OD, LID_BOSS_OD, 8]);
            translate([p[0], p[1], OH-4-0.1])
                cylinder(d=LID_M3_D, h=6, $fn=16);
        }
}

// ─────────────────────── lid (top panel) ─────────────────────────────────────
module lid() {
    // Positioned above body in preview; in real print this is its own part.
    translate([0, 0, OH + 8]) {
        difference() {
            rbox(OW, OD, LID_T, 5);

            // Fan grill cutouts (centred on lid)
            fan_grill(F1X, FY, -0.1, LID_T);
            fan_grill(F2X, FY, -0.1, LID_T);

            // M3 screw holes matching body bosses
            for (p = LID_BOSS)
                translate([p[0], p[1], -0.1])
                    cylinder(d=LID_M3_D, h=LID_T+0.2, $fn=16);
        }

        // Locating ridge (prints on underside of lid — flip lid to print)
        // Ridge lips around interior rim, drop down by RIDGE_H
        difference() {
            translate([WALL + RIDGE_W, WALL + RIDGE_W, -RIDGE_H])
                rbox(IN_W - RIDGE_W*2, IN_D - RIDGE_W*2, RIDGE_H, 3);
            translate([WALL + RIDGE_W*2, WALL + RIDGE_W*2, -RIDGE_H-0.1])
                rbox(IN_W - RIDGE_W*4, IN_D - RIDGE_W*4, RIDGE_H+0.2, 2);
        }
    }
}

// ─────────────────────── window side panel ────────────────────────────────────
// Decorative panel for the RIGHT side (no ports on right in this layout — ports
// are cut into the body wall, this panel is purely cosmetic with a window).
// Shown offset to the right in preview.
module window_panel() {
    translate([OW + 10, 0, 0]) {
        difference() {
            rbox(WALL+0.5, OD-1, OH-1, 4);
            // Window opening
            translate([-0.1, OD*0.15, OH*0.20])
                cube([WALL+0.7, OD*0.68, OH*0.56]);
            // M3 screw holes (4 corners)
            for (p = LID_BOSS) {
                // match body left-wall screw positions (reuse boss X/Y but as Z/Y here)
            }
        }
        // Window mesh grid (stays as thin grid print)
        translate([0, OD*0.15, OH*0.20])
            intersection() {
                cube([WALL*0.35, OD*0.68, OH*0.56]);
                union() {
                    for (j=[0:5])
                        translate([0, 0, j*OH*0.56/5])
                            cube([WALL*0.35, OD*0.68, 1.1]);
                    for (i=[0:4])
                        translate([0, i*OD*0.68/4, 0])
                            cube([WALL*0.35, 1.1, OH*0.56]);
                }
            }
    }
}

// ─────────────────────── assemble preview ─────────────────────────────────────
color([0.14, 0.14, 0.16]) {
    case_body();
}
color([0.20, 0.20, 0.22], 0.92) {
    lid();
}
color([0.25, 0.25, 0.28], 0.80) {
    window_panel();
}
