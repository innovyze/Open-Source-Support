# InfoWorks ICM

Welcome to the InfoWorks ICM Scripts and Model repository! This repository contains open source Ruby, SQL, Python, and other scripts for building and using [InfoWorks ICM](https://help.autodesk.com/view/IWICMS/2026/ENU/) models. Example Themes, models, and integrated workflows are provided.

## Folder Structure

| Folder | Contents |
|--------|----------|
| [01 Ruby](./01%20Ruby/) | Ruby scripts (UI and Exchange) |
| [02 SQL](./02%20SQL/) | SQL queries for network selection and manipulation |
| [03 Python](./03%20Python/) | Python tools for data analysis and automation |
| [04 Themes](./04%20Themes/) | ICM theme files and examples |
| [05 Example Models](./05%20Example%20Models/) | Sample models (Hydrology, Regulator Control, 2D Structures, Water Quality) |
| [06 End-to-End Workflows](./06%20End-to-End%20Workflows/) | Multi-step pipelines combining Ruby, Python, and batch automation |

The script folders (01–03) are organized into subfolders based on the simulation engines they support. InfoWorks ICM supports two simulation engines: the InfoWorks engine and the SWMM5 engine. Each engine has its own subfolder. When it comes to writing scripts, the main difference is each engine uses different names for objects and their attributes. For models there are often differences in functionality and terminology. It is the InfoWorks engine that has the most comprehensive set of capabilities.
