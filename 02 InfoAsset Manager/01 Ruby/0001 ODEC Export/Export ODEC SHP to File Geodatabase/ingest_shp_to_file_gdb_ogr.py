"""
Create a new File Geodatabase from IAM staging shapefiles using GDAL (no ArcGIS Pro).

Requires GDAL 3.6+ with OpenFileGDB write support and `ogr2ogr` on PATH
(for example OSGeo4W or QGIS standalone install).

Example:
  python ingest_shp_to_file_gdb_ogr.py --staging "C:\\path\\staging_shp" --gdb "C:\\Temp\\IAMFullSync.gdb"
"""

from __future__ import print_function

import argparse
import os
import re
import shutil
import subprocess
import sys

DEFAULT_LAYERS = [
    ("node.shp", "Node"),
    ("pipe.shp", "Pipe"),
]

FC_NAME_PATTERN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

COMMON_OGR2OGR_PATHS = [
    r"C:\Program Files\QGIS 4.0.3\bin\ogr2ogr.exe",
    r"C:\OSGeo4W\bin\ogr2ogr.exe",
    r"C:\Program Files\GDAL\ogr2ogr.exe",
]


def parse_layer_spec(spec):
    if ":" not in spec:
        raise ValueError(
            "Layer spec must be shapefile:FeatureClass, got: {0}".format(spec)
        )
    shp_name, fc_name = spec.split(":", 1)
    shp_name = shp_name.strip()
    fc_name = fc_name.strip()
    if not shp_name.lower().endswith(".shp"):
        shp_name = shp_name + ".shp"
    validate_fc_name(fc_name)
    return shp_name, fc_name


def validate_fc_name(name):
    if not FC_NAME_PATTERN.match(name):
        raise ValueError(
            "Invalid feature class name (use letters, numbers, underscore): {0}".format(
                name
            )
        )


def resolve_shapefile(staging_dir, shp_name):
    path = os.path.join(staging_dir, shp_name)
    if os.path.isfile(path):
        return path
    base, ext = os.path.splitext(shp_name)
    for entry in os.listdir(staging_dir):
        if entry.lower() == (base + ext).lower():
            return os.path.join(staging_dir, entry)
    raise IOError("Shapefile not found in staging folder: {0}".format(shp_name))


def find_ogr2ogr(explicit_path):
    if explicit_path:
        if not os.path.isfile(explicit_path):
            raise IOError("ogr2ogr not found: {0}".format(explicit_path))
        return explicit_path

    found = shutil.which("ogr2ogr")
    if found:
        return found

    for candidate in COMMON_OGR2OGR_PATHS:
        if os.path.isfile(candidate):
            return candidate

    raise IOError(
        "ogr2ogr not found. Install GDAL 3.6+ (OSGeo4W or QGIS) or pass --ogr2ogr."
    )


def remove_gdb(gdb_path):
    if os.path.isdir(gdb_path):
        print("Removing existing geodatabase: {0}".format(gdb_path))
        shutil.rmtree(gdb_path)


def gdal_env_for_ogr2ogr(ogr2ogr_path):
    """QGIS/OSGeo4W ogr2ogr needs GDAL_DATA (and PROJ) when not run from o4w_env.bat."""
    env = os.environ.copy()
    bin_dir = os.path.dirname(os.path.abspath(ogr2ogr_path))
    root = os.path.dirname(bin_dir)
    gdal_data = os.path.join(root, "apps", "gdal", "share", "gdal")
    proj_data = os.path.join(root, "share", "proj")
    if os.path.isdir(gdal_data):
        env["GDAL_DATA"] = gdal_data
    if os.path.isdir(proj_data):
        env["PROJ_DATA"] = proj_data
        env["PROJ_LIB"] = proj_data
    return env


def run_ogr2ogr(ogr2ogr, args):
    cmd = [ogr2ogr] + args
    print("Running: {0}".format(" ".join(cmd)))
    completed = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        env=gdal_env_for_ogr2ogr(ogr2ogr),
    )
    if completed.returncode != 0:
        err = (completed.stderr or completed.stdout or "").strip()
        raise RuntimeError("ogr2ogr failed: {0}".format(err or completed.returncode))
    if completed.stderr:
        print(completed.stderr.strip())


def load_layers(ogr2ogr, staging_dir, gdb_path, layers):
    first = True
    for shp_name, fc_name in layers:
        shp_path = resolve_shapefile(staging_dir, shp_name)
        if first:
            run_ogr2ogr(
                ogr2ogr,
                [
                    "-f",
                    "OpenFileGDB",
                    gdb_path,
                    shp_path,
                    "-nln",
                    fc_name,
                    "-overwrite",
                ],
            )
            first = False
        else:
            run_ogr2ogr(
                ogr2ogr,
                [
                    "-f",
                    "OpenFileGDB",
                    "-update",
                    gdb_path,
                    shp_path,
                    "-nln",
                    fc_name,
                    "-overwrite",
                ],
            )
    print("Done. Geodatabase: {0}".format(gdb_path))


def main():
    parser = argparse.ArgumentParser(
        description="Load IAM staging shapefiles into a new File Geodatabase via GDAL."
    )
    parser.add_argument("--staging", required=True, help="Folder with exported .shp files.")
    parser.add_argument(
        "--gdb",
        required=True,
        help="Output .gdb path (existing folder is deleted).",
    )
    parser.add_argument(
        "--ogr2ogr",
        default=None,
        help="Full path to ogr2ogr.exe if not on PATH.",
    )
    parser.add_argument(
        "--layer",
        action="append",
        dest="layers",
        metavar="file.shp:FeatureClass",
        help="Repeat per layer; default: node.shp:Node pipe.shp:Pipe",
    )
    args = parser.parse_args()

    staging_dir = os.path.abspath(args.staging)
    if not os.path.isdir(staging_dir):
        print("Staging folder does not exist: {0}".format(staging_dir), file=sys.stderr)
        sys.exit(1)

    gdb_path = os.path.abspath(args.gdb)
    if not gdb_path.lower().endswith(".gdb"):
        print("Output path must end with .gdb", file=sys.stderr)
        sys.exit(1)

    layers = (
        [parse_layer_spec(s) for s in args.layers]
        if args.layers
        else list(DEFAULT_LAYERS)
    )

    ogr2ogr = find_ogr2ogr(args.ogr2ogr)
    remove_gdb(gdb_path)
    load_layers(ogr2ogr, staging_dir, gdb_path, layers)


if __name__ == "__main__":
    main()
