"""
WS Pro — Step 3: Publish shapefile ZIP to ArcGIS Online (hosted feature layer)
===============================================================================

PURPOSE
    Publishes the shapefile ZIP produced by Step 2 to ArcGIS Online as a
    hosted feature layer, overwriting the previous week's layer if it exists.

WORKFLOW
    Step 1  →  WS_Pro_Create_and_Run_Weekly_Simulation.rb
    Step 2  →  WS_Pro_Export_Simulation_Results_to_Shapefile.rb
    Step 3  →  this script
    Orchestrate all three with Run_All_Weekly_WS_Pro_Workflow.bat

QUICK START
    1. Edit the CONFIGURATION block below:
         - Set EXPORT_DIR  to the folder where Step 2 writes the ZIP.
         - Set ZIP_FILENAME to the ZIP name used in Step 2 (default: weekly_ws_pro.zip).
         - Set AGOL_URL to your ArcGIS Online or Enterprise Portal URL.
         - Set AGOL_USERNAME or leave blank to use the AGOL_USERNAME environment variable.
         - Set AGOL_FOLDER_ID to the destination content folder (see note below).
         - Set FEATURE_LAYER_TITLE to the display name for the hosted feature layer.
         - Update the PRJ WKT constants to match your model's coordinate system.
    2. Set AGOL_PASSWORD as an environment variable in your .bat file:
         set "AGOL_PASSWORD=your_password_here"
    3. Run via:
         py -3.12 Publish_WS_Pro_Weekly_Shapefiles_to_AGOL.py

HOW TO FIND YOUR AGOL FOLDER ID
    Open the target folder in ArcGIS Online. The URL contains the folder ID:
    https://org.maps.arcgis.com/home/content.html?folder=<FOLDER_ID_HERE>

HOW TO FIND / UPDATE THE PRJ WKT
    Open your model's .prj file in a text editor after a manual export from WS Pro.
    Use the ESRI WKT shown there. Replace the "unnamed" variant in the PRJ constants
    with your project's named CRS.  The auto-detection threshold (2 000 000) assumes
    Colorado State Plane — update _detect_prj() if your false easting is different.

BEHAVIOUR (each run)
    1. Build a clean temporary ZIP from the source ZIP:
         - All shapefile components placed at the root (AGOL requires this).
         - "unnamed" .prj replaced with the correct named CRS WKT.
           Unit system auto-detected from the SHP bounding box X_min:
             X > threshold  →  feet variant PRJ
             X < threshold  →  metres variant PRJ
         - DBF fields with empty names stripped (AGOL rejects null-named cols).
         The original exported files are never modified.
    2. Search for an existing hosted feature layer with FEATURE_LAYER_TITLE.
    3. If found with a reachable service URL  →  overwrite in-place.
    4. If overwrite fails  →  delete all items with that title, then publish
       fresh with a timestamped service name (prevents endpoint collisions).

REQUIREMENTS
    Python 3.8+  |  pip install arcgis
    AGOL_PASSWORD must be set as an environment variable.
"""

from __future__ import annotations

import os
import shutil
import struct
import sys
import tempfile
import time
import urllib3
import zipfile

# ===========================================================================
# CONFIGURATION — fill in every value below before running
# ===========================================================================

# Folder where Step 2 writes the ZIP file.
EXPORT_DIR   = r"C:\WS Pro Results"

# ZIP filename produced by Step 2.
ZIP_FILENAME = "weekly_ws_pro.zip"

# ArcGIS Online or Enterprise Portal base URL.
AGOL_URL = "https://www.arcgis.com"

# AGOL username. Leave as empty string to use the AGOL_USERNAME environment variable.
AGOL_USERNAME = os.environ.get("AGOL_USERNAME", "")

# AGOL password — always read from environment variable for security.
# Set this in your .bat file:  set "AGOL_PASSWORD=your_password"
AGOL_PASSWORD = os.environ.get("AGOL_PASSWORD", "")

# ID of the AGOL content folder where the layer will be published.
# Found in the URL when browsing to the folder in AGOL.
AGOL_FOLDER_ID = "YOUR_FOLDER_ID_HERE"

# Display name for the hosted feature layer in AGOL.
FEATURE_LAYER_TITLE = "Weekly WS Pro Simulation Results"

# Prefix for the REST endpoint service name (a timestamp is appended for uniqueness).
_SERVICE_NAME_BASE = "ws_pro_weekly"

# Seconds to wait after deleting an existing layer before publishing fresh.
# AGOL needs time to release the service name; skipping this causes "name already exists" errors.
DELETE_TO_PUBLISH_DELAY = 120

# ===========================================================================
# PRJ WKT CONFIGURATION
# Replace these with the correct named CRS WKT for your project's coordinate system.
# After a manual export from WS Pro, open the .prj file to see the WKT to adapt.
#
# Two variants are required — one for feet coordinates, one for metres — because
# WS Pro Exchange writes "unnamed" in .prj regardless of unit setting. The correct
# variant is selected automatically based on the SHP bounding box X_min value.
#
# AUTO-DETECTION THRESHOLD: if X_min > _FEET_THRESHOLD assume feet, else metres.
# For Colorado State Plane Central: feet false_easting = 3 000 000, metres = 914 401.
# Update this value if your projection has different false eastings.
# ===========================================================================

_FEET_THRESHOLD = 2_000_000   # X_min > this value → coordinates are in feet

# PRJ WKT for feet coordinates.
# Default: NAD 1983 StatePlane Colorado Central FIPS 0502 (US survey feet) WKID 2232.
# Replace with the named WKT for your coordinate system.
_FEET_PRJ = (
    'PROJCS["NAD_1983_StatePlane_Colorado_Central_FIPS_0502_Feet",'
    'GEOGCS["GCS_North_American_1983",'
    'DATUM["D_North_American_1983",'
    'SPHEROID["GRS_1980",6378137.0,298.257222101]],'
    'PRIMEM["Greenwich",0.0],'
    'UNIT["Degree",0.0174532925199433]],'
    'PROJECTION["Lambert_Conformal_Conic"],'
    'PARAMETER["False_Easting",3000000.0],'
    'PARAMETER["False_Northing",1000000.0],'
    'PARAMETER["Central_Meridian",-105.5],'
    'PARAMETER["Standard_Parallel_1",39.75],'
    'PARAMETER["Standard_Parallel_2",38.45],'
    'PARAMETER["Latitude_Of_Origin",37.8333333333333],'
    'UNIT["Foot_US",0.304800609601219]]'
)

# PRJ WKT for metres coordinates.
# Default: NAD 1983 StatePlane Colorado Central FIPS 0502 (metres) ESRI WKID 102004.
# Replace with the named WKT for your coordinate system.
_METRES_PRJ = (
    'PROJCS["NAD_1983_StatePlane_Colorado_Central_FIPS_0502",'
    'GEOGCS["GCS_North_American_1983",'
    'DATUM["D_North_American_1983",'
    'SPHEROID["GRS_1980",6378137.0,298.257222101]],'
    'PRIMEM["Greenwich",0.0],'
    'UNIT["Degree",0.0174532925199433]],'
    'PROJECTION["Lambert_Conformal_Conic"],'
    'PARAMETER["False_Easting",914401.8289],'
    'PARAMETER["False_Northing",304800.6096],'
    'PARAMETER["Central_Meridian",-105.5],'
    'PARAMETER["Standard_Parallel_1",39.75],'
    'PARAMETER["Standard_Parallel_2",38.45],'
    'PARAMETER["Latitude_Of_Origin",37.8333333333333],'
    'UNIT["Meter",1.0]]'
)

# ===========================================================================
# END CONFIGURATION
# ===========================================================================

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


# ---------------------------------------------------------------------------
# ZIP preparation helpers
# ---------------------------------------------------------------------------

def _read_shp_xmin(source_zip: zipfile.ZipFile) -> float | None:
    """Read X_min from the header of the first .shp file in the ZIP (offset 36, 8-byte LE double)."""
    for member in source_zip.infolist():
        if member.filename.lower().endswith(".shp"):
            data = source_zip.read(member.filename)
            if len(data) >= 44:
                return struct.unpack_from("<d", data, 36)[0]
    return None


def _detect_prj(x_min: float) -> str:
    """Select the correct named PRJ WKT based on the bounding box X coordinate range."""
    if x_min > _FEET_THRESHOLD:
        print(f"  Detected units: feet (X_min={x_min:.0f} > {_FEET_THRESHOLD})  → feet PRJ applied")
        return _FEET_PRJ
    else:
        print(f"  Detected units: metres (X_min={x_min:.0f} ≤ {_FEET_THRESHOLD})  → metres PRJ applied")
        return _METRES_PRJ


def _fix_prj(data: bytes, named_wkt: str) -> bytes:
    """Replace an unnamed/unrecognised PRJ with the correct named CRS WKT."""
    wkt = data.decode("utf-8", errors="replace").strip()
    if "unnamed" in wkt.lower():
        return named_wkt.encode("utf-8")
    return data


def _fix_dbf(data: bytes) -> bytes:
    """
    Strip DBF field descriptors with empty names and rebuild the file.
    ArcGIS Online rejects shapefiles containing null-named attribute columns.
    """
    if len(data) < 33:
        return data

    num_records  = struct.unpack_from("<I", data, 4)[0]
    old_hdr      = struct.unpack_from("<H", data, 8)[0]
    old_rec_size = struct.unpack_from("<H", data, 10)[0]

    all_fields = []
    offset = 32
    while offset + 32 <= old_hdr and data[offset] != 0x0D:
        name = data[offset: offset + 11].split(b"\x00")[0].decode("ascii", errors="replace").strip()
        flen = data[offset + 16]
        all_fields.append({"name": name, "len": flen, "raw": data[offset: offset + 32]})
        offset += 32

    valid = [f for f in all_fields if f["name"]]
    if len(valid) == len(all_fields):
        return data  # nothing to strip

    old_offsets = []
    pos = 1
    for f in all_fields:
        old_offsets.append((pos, f["len"]))
        pos += f["len"]

    valid_idx = {i for i, f in enumerate(all_fields) if f["name"]}
    new_hdr   = 32 + len(valid) * 32 + 1
    new_rsize = 1 + sum(f["len"] for f in valid)

    hdr = bytearray(data[:32])
    struct.pack_into("<H", hdr, 8,  new_hdr)
    struct.pack_into("<H", hdr, 10, new_rsize)

    fblock = b"".join(f["raw"] for f in valid) + b"\x0D"
    fblock += b"\x00" * (new_hdr - 32 - len(fblock))

    recs = bytearray()
    for r in range(num_records):
        old_rec = data[old_hdr + r * old_rec_size: old_hdr + r * old_rec_size + old_rec_size]
        if not old_rec:
            break
        new_rec = bytearray([old_rec[0]])
        for i, (s, l) in enumerate(old_offsets):
            if i in valid_idx:
                new_rec += old_rec[s: s + l]
        recs += new_rec

    return bytes(hdr) + fblock + bytes(recs)


def _make_agol_zip(source_zip: str) -> str:
    """
    Build a temporary AGOL-ready ZIP from the source ZIP.
    Applies PRJ and DBF fixes without modifying the original files.

    IMPORTANT: the output ZIP is written to a temp directory but keeps the
    SAME filename as the source (e.g. weekly_ws_pro.zip). AGOL's overwrite()
    API rejects uploads whose filename differs from the original shapefile item.

    Returns the path to the temporary ZIP (caller must delete the directory).
    """
    tmp_dir  = tempfile.mkdtemp(prefix="ws_pro_agol_")
    tmp_path = os.path.join(tmp_dir, os.path.basename(source_zip))

    with zipfile.ZipFile(source_zip, "r") as src:
        x_min     = _read_shp_xmin(src)
        named_wkt = _detect_prj(x_min if x_min is not None else 0.0)

        with zipfile.ZipFile(tmp_path, "w", zipfile.ZIP_DEFLATED) as dst:
            seen: set[str] = set()
            for member in src.infolist():
                filename = os.path.basename(member.filename)
                if not filename or filename in seen:
                    continue
                seen.add(filename)
                data = src.read(member.filename)
                if filename.lower().endswith(".prj"):
                    data = _fix_prj(data, named_wkt)
                elif filename.lower().endswith(".dbf"):
                    data = _fix_dbf(data)
                dst.writestr(filename, data)

    print(f"  AGOL-ready ZIP prepared: {tmp_path}")
    return tmp_path


# ---------------------------------------------------------------------------
# AGOL helpers
# ---------------------------------------------------------------------------

def _unique_service_name() -> str:
    """Generate a timestamped service name to avoid REST endpoint collisions."""
    return f"{_SERVICE_NAME_BASE}_{time.strftime('%Y%m%d_%H%M%S')}"


def _find_all_by_title(gis, owner: str, title: str) -> list:
    """Return all AGOL items owned by this user with an exact title match."""
    results = gis.content.search(
        query=f'owner:{owner} AND title:"{title}"', max_items=100
    )
    return [it for it in results if it.title == title]


def _delete_all_by_title(gis, owner: str, title: str) -> None:
    """Delete every AGOL item (of any type) matching this title."""
    for it in _find_all_by_title(gis, owner, title):
        try:
            it.delete(force=True)
            print(f"  Deleted '{it.title}' [{it.type}] (id={it.id})")
        except Exception as ex:
            print(f"  Warning: could not delete {it.id}: {ex}")


def _try_overwrite(existing, agol_zip: str) -> bool:
    """Attempt an in-place overwrite of an existing hosted feature layer. Returns True on success."""
    from arcgis.features import FeatureLayerCollection
    try:
        flc    = FeatureLayerCollection.fromitem(existing)
        result = flc.manager.overwrite(agol_zip)
        if isinstance(result, dict):
            return bool(result.get("success"))
        return result is not None
    except Exception as ex:
        print(f"  Overwrite failed: {ex}")
        return False


def _publish_fresh(gis, agol_zip: str):
    """Upload the ZIP as a new shapefile item and publish it as a hosted feature layer."""
    svc_name    = _unique_service_name()
    root_folder = gis.content.folders.get()

    print(f"  Uploading {agol_zip} ...")
    shape_item = root_folder.add(
        item_properties={"title": FEATURE_LAYER_TITLE, "type": "Shapefile"},
        file=agol_zip,
    ).result()

    print(f"  Publishing as hosted service '{svc_name}' ...")
    published = shape_item.publish(publish_parameters={
        "name":           svc_name,
        "hasStaticData":  True,
        "maxRecordCount": 2000,
        "layerInfo":      {"capabilities": "Query"},
    })
    published.update({"title": FEATURE_LAYER_TITLE})

    # Move both the shapefile item and the feature layer to the target folder
    folder = {"id": AGOL_FOLDER_ID}
    for item in (shape_item, published):
        try:
            item.move(folder)
        except Exception as ex:
            print(f"  Note: could not move '{item.title}' to folder: {ex}")

    return published


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    # Validate configuration
    if not AGOL_PASSWORD:
        print("ERROR: AGOL_PASSWORD is not set. Add  set \"AGOL_PASSWORD=...\"  to your .bat file.", file=sys.stderr)
        return 1

    if AGOL_FOLDER_ID == "YOUR_FOLDER_ID_HERE":
        print("ERROR: AGOL_FOLDER_ID has not been configured. Set it in the CONFIGURATION block.", file=sys.stderr)
        return 1

    zip_path = os.path.join(EXPORT_DIR, ZIP_FILENAME)
    if not os.path.isfile(zip_path):
        print(f"ERROR: Source ZIP not found: {zip_path}", file=sys.stderr)
        return 1

    try:
        from arcgis.gis import GIS
    except ImportError:
        print("ERROR: arcgis package not installed  (pip install arcgis).", file=sys.stderr)
        return 1

    print(f"Connecting to {AGOL_URL} ...")
    gis   = GIS(AGOL_URL, AGOL_USERNAME, AGOL_PASSWORD)
    owner = gis.users.me.username
    print(f"Signed in as: {owner}\n")

    agol_zip = _make_agol_zip(zip_path)

    try:
        existing_items   = _find_all_by_title(gis, owner, FEATURE_LAYER_TITLE)
        feature_services = [it for it in existing_items if it.type == "Feature Service"]
        pub = None

        for fs in feature_services:
            print(f"Found existing layer '{fs.title}' (id={fs.id}) — attempting overwrite ...")
            if _try_overwrite(fs, agol_zip):
                fs.update({"title": FEATURE_LAYER_TITLE})
                pub = fs
                print("  Overwrite succeeded.")
                break
            print("  Overwrite failed; will delete and publish fresh.")

        if pub is None:
            if existing_items:
                print("Deleting conflicting items before fresh publish ...")
                _delete_all_by_title(gis, owner, FEATURE_LAYER_TITLE)
                if DELETE_TO_PUBLISH_DELAY > 0:
                    print(f"Waiting {DELETE_TO_PUBLISH_DELAY}s for AGOL to release the service name ...")
                    for remaining in range(DELETE_TO_PUBLISH_DELAY, 0, -10):
                        print(f"  {remaining}s remaining ...")
                        time.sleep(min(10, remaining))
            print(f"Publishing '{FEATURE_LAYER_TITLE}' as a new hosted feature layer ...")
            pub = _publish_fresh(gis, agol_zip)

        print(f"\nPublish succeeded.")
        print(f"Title : {pub.title}")
        print(f"URL   : {pub.homepage}")
        return 0

    except Exception as ex:
        print(f"\nERROR: {ex}", file=sys.stderr)
        return 1

    finally:
        try:
            shutil.rmtree(os.path.dirname(agol_zip), ignore_errors=True)
        except Exception:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
