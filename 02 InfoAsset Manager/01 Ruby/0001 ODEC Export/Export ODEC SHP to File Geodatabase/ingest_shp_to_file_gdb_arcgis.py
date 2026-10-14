"""
Create a new File Geodatabase and load IAM ODEC staging shapefiles (full sync).

Run with ArcGIS Pro's Python, e.g.:
  propy.bat ingest_shp_to_file_gdb_arcgis.py --staging "C:\\path\\staging_shp" --gdb "C:\\Temp\\IAMFullSync.gdb"
"""

from __future__ import print_function

import argparse
import os
import re
import sys

import arcpy

# Default layers if --layer is not passed (must match Ruby EXPORT_LAYERS output names)
DEFAULT_LAYERS = [
    ("node.shp", "Node"),
    ("pipe.shp", "Pipe"),
]

FC_NAME_PATTERN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def parse_layer_spec(spec):
    """Parse shapefile_name:FeatureClass from --layer."""
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


def create_fresh_file_gdb(gdb_path):
    gdb_path = os.path.abspath(gdb_path)
    if not gdb_path.lower().endswith(".gdb"):
        raise ValueError("Output path must end with .gdb: {0}".format(gdb_path))

    folder = os.path.dirname(gdb_path)
    gdb_name = os.path.basename(gdb_path)
    if not folder:
        raise ValueError("GDB path must include a folder: {0}".format(gdb_path))

    if not os.path.isdir(folder):
        os.makedirs(folder)

    if arcpy.Exists(gdb_path):
        print("Removing existing geodatabase: {0}".format(gdb_path))
        arcpy.management.Delete(gdb_path)

    print("Creating geodatabase: {0}".format(gdb_path))
    arcpy.management.CreateFileGDB(folder, gdb_name)
    return gdb_path


def load_layers(staging_dir, gdb_path, layers):
    arcpy.env.overwriteOutput = True
    for shp_name, fc_name in layers:
        shp_path = resolve_shapefile(staging_dir, shp_name)
        out_fc = os.path.join(gdb_path, fc_name)
        print("Loading {0} -> {1}".format(shp_path, out_fc))
        arcpy.conversion.FeatureClassToFeatureClass(shp_path, gdb_path, fc_name)
    print("Done. Geodatabase: {0}".format(gdb_path))


def main():
    parser = argparse.ArgumentParser(
        description="Load IAM staging shapefiles into a new File Geodatabase."
    )
    parser.add_argument(
        "--staging",
        required=True,
        help="Folder containing exported .shp files (IAM staging_shp).",
    )
    parser.add_argument(
        "--gdb",
        required=True,
        help="Full path for the new .gdb (existing .gdb is deleted).",
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

    if args.layers:
        layers = [parse_layer_spec(s) for s in args.layers]
    else:
        layers = list(DEFAULT_LAYERS)

    gdb_path = create_fresh_file_gdb(args.gdb)
    load_layers(staging_dir, gdb_path, layers)


if __name__ == "__main__":
    main()
