import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from stl import mesh

m = mesh.Mesh.from_file('/home/user/stl-test/car.stl')
tris = m.vectors

# simple lambert shading from triangle normals
n = np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0])
n /= (np.linalg.norm(n, axis=1, keepdims=True) + 1e-9)
light = np.array([0.4, -0.6, 0.7])
light = light / np.linalg.norm(light)
shade = np.clip(np.abs(n @ light), 0.25, 1.0)
base = np.array([0.20, 0.45, 0.85])          # car-blue
colors = np.clip(base[None, :] * shade[:, None] + 0.10, 0, 1)

views = [(22, -60), (18, 130), (75, -90)]    # 3/4 front, 3/4 rear, top
titles = ['3/4 front', '3/4 rear', 'top']
fig = plt.figure(figsize=(18, 6))
for k, (elev, azim) in enumerate(views):
    ax = fig.add_subplot(1, 3, k + 1, projection='3d')
    pc = Poly3DCollection(tris, facecolors=colors, edgecolors='none')
    ax.add_collection3d(pc)
    ax.set_xlim(-22, 22); ax.set_ylim(-22, 22); ax.set_zlim(-4, 30)
    ax.set_box_aspect((1, 1, 0.8))
    ax.view_init(elev=elev, azim=azim)
    ax.set_axis_off()
    ax.set_title(titles[k])
plt.tight_layout()
plt.savefig('/home/user/stl-test/car_preview.png', dpi=110,
            bbox_inches='tight', facecolor='white')
print('wrote car_preview.png')
