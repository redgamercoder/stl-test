"""
Detailed sports-car STL generator.

Coordinate system:
    X = width  (left  -  / right + )
    Y = length (rear   - / front + )
    Z = height (ground 0 / up    + )

The body and greenhouse are built as smooth *lofts* of super-ellipse
cross-sections (gives real sculpted curvature instead of flat boxes).
Wheels, lights, grille, spoiler, mirrors, exhaust, etc. are added as
separate watertight solids and unioned into one triangle soup.
"""

import math
import numpy as np
from stl import mesh

TRIS = []


# ───────────────────────── geometry helpers ──────────────────────────
def centroid(pts):
    n = len(pts)
    return (sum(p[0] for p in pts) / n,
            sum(p[1] for p in pts) / n,
            sum(p[2] for p in pts) / n)


def superellipse_section(y, hw, z0, z1, n=28, p=3.0):
    """A rounded-rectangle (super-ellipse) cross-section in the X-Z plane."""
    zc = 0.5 * (z0 + z1)
    hh = 0.5 * (z1 - z0)
    pts = []
    for k in range(n):
        a = 2.0 * math.pi * k / n
        ca, sa = math.cos(a), math.sin(a)
        x = hw * math.copysign(abs(ca) ** (2.0 / p), ca)
        z = zc + hh * math.copysign(abs(sa) ** (2.0 / p), sa)
        pts.append((x, y, z))
    return pts


def loft(sections):
    """Connect a list of equal-length cross-sections into a closed surface."""
    tris = []
    for s in range(len(sections) - 1):
        A, B = sections[s], sections[s + 1]
        N = len(A)
        for i in range(N):
            j = (i + 1) % N
            tris.append([A[i], B[i], B[j]])
            tris.append([A[i], B[j], A[j]])
    # end caps (outward normals: -Y at first section, +Y at last)
    A = sections[0]
    c = centroid(A)
    for i in range(len(A)):
        j = (i + 1) % len(A)
        tris.append([c, A[i], A[j]])
    A = sections[-1]
    c = centroid(A)
    for i in range(len(A)):
        j = (i + 1) % len(A)
        tris.append([c, A[j], A[i]])
    return tris


def _frame(p0, p1):
    p0 = np.array(p0, float)
    p1 = np.array(p1, float)
    axis = p1 - p0
    L = np.linalg.norm(axis)
    if L < 1e-9:
        return None
    axis = axis / L
    up = np.array([0.0, 0.0, 1.0])
    if abs(np.dot(axis, up)) > 0.95:
        up = np.array([1.0, 0.0, 0.0])
    u = np.cross(axis, up)
    u /= np.linalg.norm(u)
    v = np.cross(axis, u)
    return p0, p1, u, v


def cylinder_between(p0, p1, r, seg=20, caps=True):
    """Closed cylinder between two points."""
    fr = _frame(p0, p1)
    if fr is None:
        return []
    p0, p1, u, v = fr
    r0, r1 = [], []
    for k in range(seg):
        a = 2 * math.pi * k / seg
        d = math.cos(a) * u + math.sin(a) * v
        r0.append(tuple(p0 + r * d))
        r1.append(tuple(p1 + r * d))
    tris = []
    for k in range(seg):
        j = (k + 1) % seg
        tris.append([r0[k], r1[k], r1[j]])
        tris.append([r0[k], r1[j], r0[j]])
    if caps:
        c0, c1 = tuple(p0), tuple(p1)
        for k in range(seg):
            j = (k + 1) % seg
            tris.append([c0, r0[k], r0[j]])
            tris.append([c1, r1[j], r1[k]])
    return tris


def beam(p0, p1, w, h):
    """A rectangular bar (w x h cross-section) between two points."""
    fr = _frame(p0, p1)
    if fr is None:
        return []
    p0, p1, u, v = fr
    hw, hh = w / 2.0, h / 2.0
    c = []
    for end in (p0, p1):
        c.append(end + hw * u + hh * v)
        c.append(end - hw * u + hh * v)
        c.append(end - hw * u - hh * v)
        c.append(end + hw * u - hh * v)
    quads = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 3, 7, 4),
             (1, 0, 4, 5), (2, 1, 5, 6), (3, 2, 6, 7)]
    tris = []
    for a, b, cc, d in quads:
        tris.append([tuple(c[a]), tuple(c[b]), tuple(c[cc])])
        tris.append([tuple(c[a]), tuple(c[cc]), tuple(c[d])])
    return tris


def box(x0, x1, y0, y1, z0, z1):
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
         (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    f = [(0, 2, 1), (0, 3, 2), (4, 5, 6), (4, 6, 7),
         (0, 1, 5), (0, 5, 4), (2, 3, 7), (2, 7, 6),
         (0, 4, 7), (0, 7, 3), (1, 2, 6), (1, 6, 5)]
    return [[v[a], v[b], v[c]] for a, b, c in f]


# ────────────────────────────── body ─────────────────────────────────
# (y, half-width, z_bottom, z_top, super-ellipse power)
body_stations = [
    (-20.0, 8.0, 3.0, 9.6, 3.4),   # rear bumper / tail
    (-18.5, 8.9, 2.8, 10.3, 3.1),
    (-15.5, 9.4, 2.5, 10.7, 3.0),  # rear haunch bulge
    (-12.0, 9.4, 2.4, 10.7, 3.0),  # over rear wheels
    (-8.0, 9.0, 2.4, 10.6, 3.0),
    (-3.0, 9.0, 2.4, 10.4, 3.0),   # doors
    (2.0, 9.0, 2.4, 10.2, 3.0),
    (7.0, 9.2, 2.4, 9.6, 3.0),     # cowl
    (10.5, 9.4, 2.5, 9.0, 3.0),    # front haunch bulge
    (13.5, 9.0, 2.6, 8.1, 3.2),    # hood
    (16.5, 8.4, 2.8, 7.2, 3.3),    # hood front
    (18.5, 7.6, 3.0, 6.5, 3.6),    # nose top
    (20.0, 6.8, 3.2, 5.9, 4.0),    # nose tip
]
TRIS += loft([superellipse_section(y, hw, z0, z1, 28, p)
              for (y, hw, z0, z1, p) in body_stations])

# ──────────────────────── greenhouse / cabin ─────────────────────────
cabin_stations = [
    (7.5, 6.6, 9.0, 9.7, 3.0),     # base of windshield (cowl)
    (4.0, 6.6, 9.4, 12.1, 3.0),    # windshield rake
    (1.0, 6.5, 9.6, 14.3, 2.8),    # top of windshield
    (-4.0, 6.8, 9.6, 14.5, 2.8),   # roof
    (-8.0, 6.8, 9.4, 13.0, 3.0),   # rear window
    (-11.0, 6.3, 9.2, 10.6, 3.2),  # decklid
]
TRIS += loft([superellipse_section(y, hw, z0, z1, 24, p)
              for (y, hw, z0, z1, p) in cabin_stations])

# ──────────────────────────── wheels ─────────────────────────────────
def wheel(side, yc, R=4.2, zc=4.2, inner=7.4, outer=10.6, seg=24):
    t = []
    x_in, x_face = side * inner, side * (outer - 0.6)
    t += cylinder_between((x_in, yc, zc), (x_face, yc, zc), R, seg)      # tyre
    t += cylinder_between((x_in, yc, zc), (x_face, yc, zc), R * 0.62, seg)  # inner barrel
    hub = side * outer
    t += cylinder_between((x_face, yc, zc), (hub, yc, zc), 0.9, 14)      # hub cap
    for k in range(5):                                                   # 5 spokes
        a = 2 * math.pi * k / 5
        y2 = yc + R * 0.78 * math.cos(a)
        z2 = zc + R * 0.78 * math.sin(a)
        t += beam((side * (outer - 0.35), yc, zc),
                  (side * (outer - 0.35), y2, z2), 0.8, 0.45)
    return t

for side in (-1, 1):
    TRIS += wheel(side, 12.0)    # front
    TRIS += wheel(side, -12.0)   # rear

# ──────────────────────── front-end details ──────────────────────────
# headlights (swept lenses)
for side in (-1, 1):
    TRIS += cylinder_between((side * 5.6, 17.9, 6.1),
                             (side * 5.2, 19.7, 6.4), 1.5, 16)
# grille slats
for zz in (3.9, 4.5, 5.1, 5.7):
    TRIS += beam((-4.6, 19.5, zz), (4.6, 19.5, zz), 0.55, 0.32)
# front splitter lip
TRIS += box(-7.2, 7.2, 19.8, 20.7, 2.6, 3.1)
# lower intake corners
for side in (-1, 1):
    TRIS += box(side * 4.6, side * 7.0, 19.4, 20.2, 3.2, 4.4)

# ──────────────────────── rear-end details ───────────────────────────
# full-width light bar + corner clusters
TRIS += box(-8.0, 8.0, -20.15, -19.75, 6.5, 7.0)
for side in (-1, 1):
    TRIS += box(side * 3.0, side * 8.0, -20.15, -19.6, 5.7, 7.4)
# rear bumper + diffuser fins
TRIS += box(-7.6, 7.6, -20.7, -20.0, 2.6, 3.5)
for x in (-6, -3.5, -1, 1, 3.5, 6):
    TRIS += beam((x, -20.0, 2.8), (x, -20.9, 3.7), 0.4, 1.0)
# twin exhausts
for side in (-1, 1):
    TRIS += cylinder_between((side * 3.6, -19.4, 2.5),
                             (side * 3.6, -21.1, 2.5), 0.7, 14)

# rear wing: two uprights + blade
for side in (-1, 1):
    TRIS += beam((side * 7.0, -17.6, 10.2), (side * 7.0, -18.3, 12.6), 0.6, 1.3)
TRIS += box(-8.4, 8.4, -18.7, -17.3, 12.4, 13.0)

# ──────────────────────── side details ───────────────────────────────
# door handles
for side in (-1, 1):
    TRIS += box(side * 8.6, side * 9.2, -1.2, 1.2, 8.5, 9.0)
# side mirrors (stalk + head)
for side in (-1, 1):
    TRIS += beam((side * 6.4, 6.6, 10.8), (side * 9.0, 7.1, 11.2), 0.5, 0.5)
    TRIS += box(side * 8.6, side * 10.0, 6.3, 7.5, 10.6, 11.7)
# rocker side skirts
for side in (-1, 1):
    TRIS += box(side * 8.8, side * 9.4, -10.0, 9.0, 2.2, 3.0)

# ──────────────────────────── export ─────────────────────────────────
data = np.zeros(len(TRIS), dtype=mesh.Mesh.dtype)
m = mesh.Mesh(data)
for i, tri in enumerate(TRIS):
    for j in range(3):
        m.vectors[i][j] = tri[j]
m.save('/home/user/stl-test/car.stl')

mins = m.vectors.reshape(-1, 3).min(axis=0)
maxs = m.vectors.reshape(-1, 3).max(axis=0)
print(f"Saved car.stl  |  triangles: {len(TRIS)}")
print(f"bounds  X[{mins[0]:.1f},{maxs[0]:.1f}]  "
      f"Y[{mins[1]:.1f},{maxs[1]:.1f}]  Z[{mins[2]:.1f},{maxs[2]:.1f}]")
