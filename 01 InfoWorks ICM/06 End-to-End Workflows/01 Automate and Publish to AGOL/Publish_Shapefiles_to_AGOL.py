"""
=============================================================================
Publish Shapefiles to ArcGIS Online - Python Script
=============================================================================

WORKFLOW POSITION: Step 4 of 4 in the daily simulation pipeline
  (1) Download_NWS_Rainfall.rb -> (2) Create and Run Simulations.rb
  -> (3) Export 2D ICM Results.rb -> (4) THIS SCRIPT

PURPOSE:
  Publishes 24h.zip and 48h.zip (ICM simulation result shapefiles) to ArcGIS
  Online as hosted feature layers. Uses overwrite when an existing layer is
  found; otherwise deletes conflicting items, waits for AGOL cleanup, then
  publishes new.

PREREQUISITES:
  - 24h.zip and 48h.zip must exist in SHAPEFILE_EXPORT_DIR (from Export 2D ICM Results.rb).
  - ArcGIS API for Python: pip install arcgis (use Python 3.9-3.12; 3.14 may fail).
  - ArcGIS Online account with permissions to create/publish content.

RUN METHODS:
  - py -3.12 Publish_Shapefiles_to_AGOL.py
  - Publish_Shapefiles_to_AGOL.bat
  - Run_All_Daily_Workflow.bat (runs full pipeline)

CUSTOMIZATION FOR YOUR SITE:
  Edit AGOL_URL, AGOL_USERNAME, AGOL_PASSWORD, SHAPEFILE_EXPORT_DIR,
  AGOL_FOLDER_ID, and SHAPEFILES_TO_PUBLISH in the configuration section.
  To find your folder ID: open the folder in AGOL; the URL contains folder=xxxxxxxx.
  DELETE_TO_PUBLISH_DELAY: seconds to wait after deleting items before republishing
  (AGOL may need time to release the service name).

REFERENCES:
  - https://developers.arcgis.com/python/latest/samples/publishing-sd-shapefiles-and-csv/
  - https://developers.arcgis.com/python/latest/samples/overwriting-feature-layers/

=============================================================================
"""

import os
import time
from arcgis.gis import GIS
from arcgis.features import FeatureLayerCollection

# Delay (seconds) after deleting items so AGOL can release the service name
DELETE_TO_PUBLISH_DELAY = 120  # 2 minutes

# =============================================================================
# CUSTOMIZATION: Configure these settings for your environment
# =============================================================================

# ArcGIS Online connection
# Public AGOL: "https://www.arcgis.com". Organization: "https://yourorg.maps.arcgis.com"
AGOL_URL = "https://www.arcgis.com"
AGOL_USERNAME = "your_username"

# PASSWORD: Set your password using ONE of these options:
# Option 1 (hardcoded): Replace "your_password_here" with your actual password:
AGOL_PASSWORD = "your_password_here"

# Option 2 (environment variable - more secure): Comment out the line above and use:
# AGOL_PASSWORD = os.environ.get("AGOL_PASSWORD", "")
# Then set AGOL_PASSWORD in your system environment or run: set AGOL_PASSWORD=your_password

if not AGOL_PASSWORD or AGOL_PASSWORD == "your_password_here":
    raise ValueError(
        "AGOL password not set. Replace 'your_password_here' on line 35 with your password, "
        "or set AGOL_PASSWORD environment variable."
    )

# Local path to the folder containing the shapefile zip files (24h.zip, 48h.zip)
# Use same OUTPUT_BASE as Export 2D ICM Results.rb if running the full pipeline
import os as _os
SCRIPT_DIR = _os.path.dirname(_os.path.abspath(__file__))
SHAPEFILE_EXPORT_DIR = _os.path.join(SCRIPT_DIR, "shapefile_exports")  # or e.g. r"D:\MyProject\Shapefile Exports"

# AGOL folder ID where hosted feature layers will be published
# To find: Open the folder in AGOL, URL contains folder=xxxxxxxx
AGOL_FOLDER_ID = "your_folder_id"

# Shapefiles to publish: (zip_filename, display_title_as_feature_layer)
# The display title is how the feature layer will appear in ArcGIS Online
SHAPEFILES_TO_PUBLISH = [
    ("24h.zip", "24 hour Past Simulation Results"),
    ("48h.zip", "48 hour Future Simulation Results"),
]

# =============================================================================
# Script logic (no need to modify below unless customizing behavior)
# =============================================================================


def _title_to_service_name(title):
    """Convert display title to valid AGOL service name (alphanumeric + underscores)."""
    import re
    return re.sub(r"[^\w]+", "_", title).strip("_").lower() or "service"


def _find_existing_feature_layer(gis, title, custom_service_name, zip_base_name):
    """
    Find an existing hosted feature layer we own that matches our service.
    Uses multiple search strategies since item title/name can vary (e.g. "48h" vs "48 hour Future Simulation Results").
    """
    owner = gis.users.me.username
    # Types that indicate a hosted feature layer
    featurer_types = ("Feature Service", "Feature Layer", "Feature Layer Collection")

    for search_term in (title, custom_service_name, zip_base_name):
        for item in gis.content.search(
            query=f'owner:{owner} AND typekeywords:"Hosted Service"',
            max_items=200
        ):
            if item.type not in featurer_types:
                continue
            # Match by title, item name, or service name in URL
            item_name = getattr(item, "name", "") or ""
            item_url = getattr(item, "url", "") or ""
            if (
                item.title == search_term
                or item_name == search_term
                or item_name == custom_service_name
                or custom_service_name in item_url
                or search_term in item.title
            ):
                return item
    return None


def delete_existing_items(gis, title, service_name):
    """
    Search for and delete existing items (shapefile + feature layer) that could
    conflict with the new service. Searches by display title and by service name.
    Returns the number of items deleted.
    """
    owner = gis.users.me.username
    seen_ids = set()
    deleted_count = 0

    for search_title in (title, service_name):
        query = f'owner:{owner} AND title:"{search_title}"'
        for item in gis.content.search(query=query, max_items=20):
            if item.id in seen_ids:
                continue
            seen_ids.add(item.id)
            try:
                item.delete(force=True)
                print(f"  Deleted existing: {item.title} ({item.type})")
                deleted_count += 1
            except Exception as e:
                print(f"  Warning: Could not delete {item.title}: {e}")

    # Search Feature Service items by name or title matching our service name
    for item in gis.content.search(
        query=f'owner:{owner}', item_type="Feature Service", max_items=100
    ):
        if getattr(item, "name", None) == service_name or item.title == service_name:
            if item.id in seen_ids:
                continue
            seen_ids.add(item.id)
            try:
                item.delete(force=True)
                print(f"  Deleted existing service: {item.title} (name={getattr(item, 'name', '?')})")
                deleted_count += 1
            except Exception as e:
                print(f"  Warning: Could not delete {item.title}: {e}")

    return deleted_count


def publish_shapefile(gis, zip_path, title, folder_id):
    """
    Add shapefile zip to AGOL, publish as hosted feature layer, and place in folder.
    Deletes existing items with same title first to overwrite.
    """
    if not os.path.exists(zip_path):
        print(f"  Skipping {zip_path}: File not found")
        return False

    # Use a custom service name derived from the title to avoid conflicts with
    # existing services (e.g. "24h" from zip filename may already exist in the org)
    custom_service_name = _title_to_service_name(title)
    zip_base_name = os.path.splitext(os.path.basename(zip_path))[0]

    # Overwrite-first: if we own an existing feature layer, overwrite it instead of delete+republish
    existing = _find_existing_feature_layer(gis, title, custom_service_name, zip_base_name)
    if existing:
        print(f"  Overwriting existing feature layer...")
        flc = FeatureLayerCollection.fromitem(existing)
        result = flc.manager.overwrite(zip_path)
        if result.get("success"):
            existing.update({"title": title})
            existing.move({"id": folder_id})
            print(f"  Overwrote: {existing.title} (Feature layer (hosted))")
            print(f"  URL: {existing.homepage}")
            return True
        print(f"  Overwrite failed: {result}, falling back to delete + publish...")

    # No existing layer found (or overwrite failed): delete any orphaned items, then publish new
    deleted_count = delete_existing_items(gis, title, custom_service_name)
    if deleted_count > 0 and DELETE_TO_PUBLISH_DELAY > 0:
        print(f"  Waiting {DELETE_TO_PUBLISH_DELAY}s for AGOL to release service name...")
        for remaining in range(DELETE_TO_PUBLISH_DELAY, 0, -5):
            print(f"    {remaining}s remaining...")
            time.sleep(min(5, remaining))
        time.sleep(DELETE_TO_PUBLISH_DELAY % 5)

    # Get root folder, add to it, then move items to target folder
    root_folder = gis.content.folders.get()

    # Add shapefile zip to portal
    item_properties = {"title": title, "type": "Shapefile"}
    print(f"  Uploading {zip_path}...")
    shapefile_item = root_folder.add(
        item_properties=item_properties, file=zip_path
    ).result()

    # Publish shapefile as hosted feature layer with custom service name
    publish_params = {
        "name": custom_service_name,
        "hasStaticData": True,
        "maxRecordCount": 2000,
        "layerInfo": {"capabilities": "Query"},
    }
    print(f"  Publishing as feature layer (service: {custom_service_name})...")
    published_item = shapefile_item.publish(publish_parameters=publish_params)

    # Ensure the feature layer has the correct display title
    published_item.update({"title": title})

    # Move both items to target folder
    folder_dict = {"id": folder_id}
    shapefile_item.move(folder_dict)
    published_item.move(folder_dict)

    print(f"  Published: {published_item.title} (Feature layer (hosted))")
    print(f"  URL: {published_item.homepage}")
    return True


def main():
    print("Connecting to ArcGIS Online...")
    gis = GIS(AGOL_URL, AGOL_USERNAME, AGOL_PASSWORD)
    print(f"Connected as: {gis.users.me.username}\n")

    for zip_filename, display_title in SHAPEFILES_TO_PUBLISH:
        zip_path = os.path.join(SHAPEFILE_EXPORT_DIR, zip_filename)
        print(f"Processing {zip_filename} -> '{display_title}'")
        publish_shapefile(gis, zip_path, display_title, AGOL_FOLDER_ID)
        print()

    print("Publishing complete.")


if __name__ == "__main__":
    main()
