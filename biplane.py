import numpy as np
from stl import mesh

triangles = []

def box(x0, x1, y0, y1, z0, z1):
    """Return triangles for an axis-aligned box."""
    verts = [
        (x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
        (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1),
    ]
    faces = [
        (0,2,1),(0,3,2),  # bottom
        (4,5,6),(4,6,7),  # top
        (0,1,5),(0,5,4),  # front
        (2,3,7),(2,7,6),  # back
        (0,4,7),(0,7,3),  # left
        (1,2,6),(1,6,5),  # right
    ]
    tris = []
    for f in faces:
        tris.append([verts[f[0]], verts[f[1]], verts[f[2]]])
    return tris

def cylinder_along_x(cx, y_center, z_center, r, length, segments=12):
    """Return triangles for a cylinder aligned along X axis."""
    tris = []
    angles = [2*np.pi*i/segments for i in range(segments)]
    x0, x1 = cx, cx + length
    for i in range(segments):
        a0, a1 = angles[i], angles[(i+1) % segments]
        y0c, z0c = y_center + r*np.cos(a0), z_center + r*np.sin(a0)
        y1c, z1c = y_center + r*np.cos(a1), z_center + r*np.sin(a1)
        # side quads
        tris.append([(x0,y0c,z0c),(x1,y0c,z0c),(x1,y1c,z1c)])
        tris.append([(x0,y0c,z0c),(x1,y1c,z1c),(x0,y1c,z1c)])
        # end caps
        tris.append([(x0,y_center,z_center),(x0,y1c,z1c),(x0,y0c,z0c)])
        tris.append([(x1,y_center,z_center),(x1,y0c,z0c),(x1,y1c,z1c)])
    return tris

def wing(x_start, x_end, y_root, y_tip, z, thickness=0.8, taper=True):
    """Tapered wing as a box (simplified airfoil cross-section)."""
    return box(x_start, x_end, y_root, y_tip, z - thickness/2, z + thickness/2)

def strut(x, y0, y1, z0, z1, w=0.3):
    """Diagonal strut between wings."""
    tris = []
    # approximate as a thin box; for diagonal we use a tilted quad strip
    # simplified: just a thin rectangle box
    tris += box(x - w/2, x + w/2, y0, y1, z0, z1)
    return tris

# ── Fuselage ──────────────────────────────────────────────────────────────────
# Main body: elongated box along Y axis
triangles += box(-2.5, 2.5, -10, 10, -1.5, 1.5)   # fuselage body

# Nose cone (tapered box)
triangles += box(-1.5, 1.5, 10, 14, -1.0, 1.0)     # nose section
triangles += box(-0.8, 0.8, 14, 16, -0.6, 0.6)     # nose tip

# Tail section (narrower)
triangles += box(-1.5, 1.5, -14, -10, -1.0, 1.0)   # tail

# ── Engine / Cowling ──────────────────────────────────────────────────────────
triangles += cylinder_along_x(-2, 0, 14, 2.2, 0, segments=16)   # cowling ring (flat disc)
triangles += box(-2.5, 2.5, 12, 16, -2.5, 2.5)                  # engine block

# ── Propeller ─────────────────────────────────────────────────────────────────
triangles += box(-0.3, 0.3, 16, 19, -0.4, 0.4)    # blade 1 (vertical)
triangles += box(-3.5, 3.5, 15.5, 16.5, -0.4, 0.4)  # blade 2 (horizontal)
triangles += cylinder_along_x(-0.4, -0.1, 16, 0.5, 0.8, segments=8)  # hub

# ── Upper Wing ────────────────────────────────────────────────────────────────
# Spans wide, sits above fuselage
triangles += box(-18, 18, -1, 1, 4.5, 5.5)          # upper wing main

# ── Lower Wing ────────────────────────────────────────────────────────────────
# Slightly shorter, sits at fuselage mid-level
triangles += box(-14, 14, -1, 1, 0.5, 1.5)          # lower wing main

# ── Wing Struts (4x: left-front, left-rear, right-front, right-rear) ─────────
for x_pos in [-1.2, 1.2]:
    for y_side in [-1, 1]:
        y_val = y_side * 12
        triangles += strut(x_pos, min(0, y_val), max(0, y_val), 1.5, 4.5, w=0.25)

# ── Tail Fins ─────────────────────────────────────────────────────────────────
# Vertical stabilizer
triangles += box(-0.4, 0.4, -14, -10, 1.5, 5.5)

# Horizontal stabilizers
triangles += box(-6, 6, -14, -12, -0.5, 0.5)

# ── Landing Gear ──────────────────────────────────────────────────────────────
for x_pos in [-3, 3]:
    # strut down
    triangles += box(x_pos - 0.3, x_pos + 0.3, 3, 5, -5, 0.5)
    # wheel
    triangles += cylinder_along_x(x_pos - 1.2, 4, -5.5, 1.2, 2.4, segments=12)

# Tail skid
triangles += box(-0.3, 0.3, -15, -13, -3.5, 0.5)

# ── Cockpit / Windshield ──────────────────────────────────────────────────────
triangles += box(-1.8, 1.8, 6, 10, 1.5, 3.5)   # cockpit opening
triangles += box(-1.5, 1.5, 8, 10, 3.5, 4.5)   # windshield frame

# ── Build mesh ────────────────────────────────────────────────────────────────
n = len(triangles)
biplane = mesh.Mesh(np.zeros(n, dtype=mesh.Mesh.dtype))
for i, tri in enumerate(triangles):
    for j in range(3):
        biplane.vectors[i][j] = tri[j]

biplane.save('/home/user/stl-test/biplane.stl')
print(f"Saved biplane.stl with {n} triangles")
