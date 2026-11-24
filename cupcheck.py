#!/usr/bin/env python3
"""
cupcheck.py - find suction cups in a part for bottom-up (MSLA) resin printing.

A "cup" is any pocket of liquid resin that, at the moment a layer is cured, is
enclosed by cured material on every side except the one against the FEP: there is
no path through the already-printed layers (or round the outside) for resin to flow
back in when the platform lifts. That includes:
  - holes / pockets whose bottom end is sealed against the build plate,
  - blind holes that open towards the FEP,
  - fully enclosed hollows.

How it works: the part is sliced bottom-up (z=0 = build plate). Each layer is
rasterised, and the empty space in it is split into connected regions. A union-find
links each region to the regions it touches in the layer below. A region is
"vented" if it is connected - through this layer or anything below it - to the open
space round the part. Unvented regions on a layer are reported as cups.

Usage:
  cupcheck.py part.stl [--flip] [--dz 0.1] [--xy 0.1] [--min-area 0.2] [--png out.png]
             [--stl-out cups.stl]

  --flip      print orientation is upside-down from the STL (e.g. the lid, which is
              modelled mould-face-down but printed top-face-down)
  --dz        layer step to check, mm (default 0.1; smaller = slower, finer)
  --xy        raster resolution, mm (default 0.1)
  --min-area  ignore cups smaller than this, mm^2 (default 0.2)
  --png       save a plan-view image with cups marked in red
  --stl-out   save the cup volumes as an STL in the SAME coordinates as the input
              (e.g. to overlay in OpenSCAD with show_cups). Written even when there
              are no cups (as an empty-ish marker file) so a stale one is overwritten.
  --stl-res   voxel size of the --stl-out mesh, mm (default 0.2)

Exit code: 0 = no cups, 1 = cups found, 2 = error.
Needs: numpy, trimesh, scipy, pillow, networkx. In a venv:
  python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

Supports are not modelled: run it on the part as it sits on the plate. A part on
supports gets resin under it, so a hole that is open at the bottom is not a cup there.
"""
import argparse
import sys

import numpy as np
import trimesh
from PIL import Image, ImageDraw
from scipy import ndimage


class DSU:
    def __init__(self):
        self.parent, self.vented = [], []

    def add(self, vented):
        self.parent.append(len(self.parent))
        self.vented.append(vented)
        return len(self.parent) - 1

    def find(self, a):
        p = self.parent
        while p[a] != a:
            p[a] = p[p[a]]
            a = p[a]
        return a

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[rb] = ra
            self.vented[ra] = self.vented[ra] or self.vented[rb]


def rasterise(path2d, nx, ny, xy, pad):
    """Solid mask (True = material) for one slice."""
    out = np.zeros((ny, nx), bool)
    if path2d is None:
        return out
    # Even-odd fill: XOR every closed outline. Handles holes, and islands inside
    # holes, without needing to work out which ring is inside which.
    for ring in path2d.discrete:
        if len(ring) < 3:
            continue
        img = Image.new("1", (nx, ny), 0)
        ImageDraw.Draw(img).polygon([(x / xy + pad, y / xy + pad) for x, y in ring], fill=1)
        out ^= np.array(img, dtype=bool)
    return out


def voxel_surface(vol):
    """Outer surface of a boolean voxel volume (x, y, z) as a Trimesh, 1 unit per voxel.
    Only faces between filled and empty voxels are emitted, so it stays small."""
    v = np.pad(vol, 1)
    quads = []
    # (axis, step, the 4 corner offsets of the face on that side of the voxel)
    sides = [
        (0, -1, [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
        (0, +1, [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]),
        (1, -1, [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
        (1, +1, [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]),
        (2, -1, [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]),
        (2, +1, [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]),
    ]
    for axis, step, corners in sides:
        nb = np.roll(v, -step, axis=axis)
        idx = np.argwhere(v & ~nb) - 1           # back to unpadded voxel coords
        if len(idx):
            quads.append(idx[:, None, :] + np.array(corners)[None, :, :])
    if not quads:
        return None
    q = np.concatenate(quads).reshape(-1, 3)
    verts, inv = np.unique(q, axis=0, return_inverse=True)
    inv = inv.reshape(-1, 4)
    faces = np.concatenate([inv[:, [0, 1, 2]], inv[:, [0, 2, 3]]])
    return trimesh.Trimesh(vertices=verts.astype(float), faces=faces, process=False)


def write_cup_stl(a, cup_layers, cups, nx, ny, pad, offset):
    """Cup volumes as a mesh, in the input file's coordinates."""
    mesh = None
    if cups and cup_layers:
        f = max(1, int(round(a.stl_res / a.xy)))     # xy pooling factor
        fz = max(1, int(round(a.stl_res / a.dz)))    # z pooling factor
        keys = sorted(cup_layers)
        k0, k1 = keys[0], keys[-1]
        nz = k1 - k0 + 1
        vol = np.zeros((-(-nx // f), -(-ny // f), -(-nz // fz)), bool)
        for k in keys:
            m2 = cup_layers[k].T                     # (nx, ny)
            px = np.zeros((vol.shape[0] * f, vol.shape[1] * f), bool)
            px[:nx, :ny] = m2
            pooled = px.reshape(vol.shape[0], f, vol.shape[1], f).any(axis=(1, 3))
            vol[:, :, (k - k0) // fz] |= pooled
        mesh = voxel_surface(vol)
        if mesh is not None:
            mesh.apply_scale([a.xy * f, a.xy * f, a.dz * fz])
            mesh.apply_translation([-pad * a.xy, -pad * a.xy, k0 * a.dz])
    if mesh is None:
        # Nothing to show: a tiny tetrahedron far below the plate, so the file exists
        # and any stale overlay is replaced.
        mesh = trimesh.Trimesh(vertices=[[0, 0, -1000], [0.01, 0, -1000], [0, 0.01, -1000], [0, 0, -999.99]],
                               faces=[[0, 2, 1], [0, 1, 3], [1, 2, 3], [0, 3, 2]])
    # back to the input file's coordinates (undo the sit-on-zero, then the flip)
    mesh.apply_translation(offset)
    if a.flip:
        mesh.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0]))
    mesh.export(a.stl_out)
    print(f"  cup volumes saved to {a.stl_out}" + ("" if cups else " (none - placeholder only)"))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("stl")
    ap.add_argument("--flip", action="store_true")
    ap.add_argument("--dz", type=float, default=0.1)
    ap.add_argument("--xy", type=float, default=0.1)
    ap.add_argument("--min-area", type=float, default=0.2)
    ap.add_argument("--png")
    ap.add_argument("--stl-out")
    ap.add_argument("--stl-res", type=float, default=0.2, help="voxel size of --stl-out, mm (default 0.2)")
    a = ap.parse_args()

    try:
        m = trimesh.load(a.stl, force="mesh")
    except Exception as e:
        print(f"error: can't load {a.stl}: {e}", file=sys.stderr)
        return 2
    if a.flip:
        m.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0]))
    offset = m.bounds[0].copy()
    m.apply_translation(-offset)  # sit it on z=0, x/y from 0
    if not m.is_watertight:
        print("warning: mesh is not watertight - results may be unreliable", file=sys.stderr)

    pad = 3
    ext = m.extents
    nx = int(np.ceil(ext[0] / a.xy)) + 2 * pad
    ny = int(np.ceil(ext[1] / a.xy)) + 2 * pad
    heights = np.arange(a.dz / 2, ext[2], a.dz)
    slices = m.section_multiplane(plane_origin=[0, 0, 0], plane_normal=[0, 0, 1], heights=heights)

    dsu = DSU()
    prev_lab, prev_ids = None, None
    pix_area = a.xy * a.xy
    cup_rows = []             # (z, area_mm2, cx, cy) per unvented region per layer
    cupdsu = DSU()            # groups cup rows into pockets (connected while still sealed)
    prev_cup_row = {}         # region label on previous layer -> cup row index
    cup_layers = {}           # layer index -> 2D mask of cup pixels (for --stl-out)
    cup_map = np.zeros((ny, nx), bool)
    footprint = np.zeros((ny, nx), bool)

    for k, (z, sl) in enumerate(zip(heights, slices)):
        solid = rasterise(sl, nx, ny, a.xy, pad)
        footprint |= solid
        void = ~solid
        lab, n = ndimage.label(void)  # 4-connected
        # regions touching the image border are the open space round the part
        border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
        ids = np.zeros(n + 1, int)
        for r in range(1, n + 1):
            ids[r] = dsu.add(r in border)
        pairs = []
        if prev_lab is not None:
            both = (lab > 0) & (prev_lab > 0)
            pairs = np.unique(np.stack([lab[both], prev_lab[both]], 1), axis=0)
            for r, q in pairs:
                dsu.union(ids[r], prev_ids[q])
        # vented status after linking to everything below
        bad = np.zeros(n + 1, bool)
        for r in range(1, n + 1):
            bad[r] = not dsu.vented[dsu.find(ids[r])]
        cur_cup_row = {}
        for r in np.nonzero(bad)[0]:
            m_r = lab == r
            yy, xx = np.nonzero(m_r)
            cup_rows.append((z, len(xx) * pix_area, (xx.mean() - pad) * a.xy, (yy.mean() - pad) * a.xy))
            cur_cup_row[r] = cupdsu.add(False)
            cup_map |= m_r
            if a.stl_out:
                cup_layers[k] = cup_layers.get(k, np.zeros((ny, nx), bool)) | m_r
        # a cup region touching a cup region on the layer below is the same pocket
        if prev_lab is not None and cur_cup_row and prev_cup_row:
            for r, q in pairs:
                if r in cur_cup_row and q in prev_cup_row:
                    cupdsu.union(cur_cup_row[r], prev_cup_row[q])
        prev_cup_row = cur_cup_row
        prev_lab, prev_ids = lab, ids

    orient = "flipped" if a.flip else "as modelled"
    print(f"{a.stl}: {len(heights)} layers checked at {a.dz} mm, {a.xy} mm raster, orientation {orient}")
    # Group rows by the cup they belong to (final union-find root): a pocket that is
    # one connected volume is one cup, however many layers it spans.
    cups = {}
    for i, row in enumerate(cup_rows):
        cups.setdefault(cupdsu.find(i), []).append(row)
    cups = [rows for rows in cups.values() if max(r[1] for r in rows) >= a.min_area]
    if not cups:
        print("  no suction cups found")
        rc = 0
    else:
        cups.sort(key=lambda rows: (round(rows[0][3], 1), round(rows[0][2], 1)))
        print(f"  {len(cups)} suction cup(s):")
        for rows in cups:
            z0, z1 = min(r[0] for r in rows) - a.dz / 2, max(r[0] for r in rows) + a.dz / 2
            big = max(rows, key=lambda r: r[1])
            print(f"   - z {z0:6.2f} to {z1:6.2f} mm   max area {big[1]:7.2f} mm^2   "
                  f"at x={big[2]:6.2f}, y={big[3]:6.2f} mm (from the part's min corner)")
        rc = 1

    if a.stl_out:
        write_cup_stl(a, cup_layers, cups, nx, ny, pad, offset)

    if a.png:
        img = np.full((ny, nx, 3), 245, np.uint8)
        img[footprint] = (120, 140, 170)
        img[cup_map] = (220, 30, 30)
        Image.fromarray(img[::-1]).resize((nx * 3, ny * 3), Image.NEAREST).save(a.png)
        print(f"  plan view saved to {a.png} (red = cup, seen from above)")
    return rc


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(2)
