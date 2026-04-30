# End-to-End Workflows

Complete, multi-step workflow examples that chain together multiple scripts, languages, and external systems to accomplish a full task from start to finish.

## What belongs here

- Pipelines that span **more than one language** (e.g. Ruby + Python + batch)
- Workflows with a defined **start** (data acquisition, model setup) and **end** (published output, report, dashboard update)
- Examples that are designed to run as a **sequence of steps**, often orchestrated by a batch file or scheduler
- Templates that users can adapt for their own sites by filling in configuration values

## Current examples

| Subfolder | Description |
|-----------|-------------|
| [01 Automate and Publish to AGOL](./01%20Automate%20and%20Publish%20to%20AGOL/) | Daily pipeline: download NWS rainfall → run ICM simulations → export shapefiles → publish to ArcGIS Online |
