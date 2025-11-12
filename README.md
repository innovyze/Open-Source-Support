<div align="center">

# 🌊 Autodesk Water Infrastructure Open Source Support

**Empowering the water modeling community with open-source scripts, tools, and automation**

[![Ruby](https://img.shields.io/badge/Ruby-Scripts-CC342D?style=flat&logo=ruby&logoColor=white)](https://github.com/innovyze/Open-Source-Support)
[![SQL](https://img.shields.io/badge/SQL-Queries-4479A1?style=flat&logo=postgresql&logoColor=white)](https://github.com/innovyze/Open-Source-Support)
[![Python](https://img.shields.io/badge/Python-Automation-3776AB?style=flat&logo=python&logoColor=white)](https://github.com/innovyze/Open-Source-Support)
[![License](https://img.shields.io/badge/License-Open%20Source-green?style=flat)](https://github.com/innovyze/Open-Source-Support)

---

### 📊 [**View Live Traffic Analytics Dashboard →**](https://innovyze.github.io/Open-Source-Support/)

*Track repository activity, views, and community engagement in real-time*

---

</div>

## What's Inside

This repository is your **central hub** for open-source code that enhances Autodesk Water Infrastructure products:

- **Ruby Scripts** - UI automation and Exchange API integrations
- **SQL Queries** - Advanced network object selection and manipulation  
- **Python Tools** - Data analysis, visualization, and workflow automation
- **Documentation** - Comprehensive guides and best practices
- **VBScript** - Legacy automation and integration tools

> 📚 **Pro Tip**: Check out the [Exchange documentation](https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=Innovyze_Exchange_Introduction_ICM_introduction_html) for complete Ruby API reference

## Quick Start

### Browse by Product

| Product | Description | Scripts Available |
|---------|-------------|-------------------|
| [**InfoWorks ICM**](./01%20InfoWorks%20ICM/) | Integrated Catchment Modeling | Ruby, SQL, Python |
| [**InfoAsset Manager**](./02%20InfoAsset%20Manager/) | Asset Management Platform | Ruby Scripts |
| [**ICMLive**](./03%20ICMLive/) | Real-time Operational Platform | Data Formats, APIs |
| [**InfoWorks WS Pro**](./04%20InfoWorks%20WS%20Pro/) | Water Distribution Modeling | Ruby, SQL, VBScript |
| [**InfoWater Pro**](./05%20InfoWater%20Pro/) | ArcGIS-based Water Modeling | Python Integration |
| [**XPSWMM**](./06%20XPSWMM/) | Stormwater & Flooding Analysis | Tutorials, Resources |

## Featured Scripts

### Most Popular

- **[Convert Polygon to Mesh Level Zone](./01%20InfoWorks%20ICM/01%20Ruby/01%20InfoWorks/0077%20-%20Convert%20Polygon%20to%20Mesh%20level%20zone/)** - Transform 2D zone definitions
- **[Calculate Runoff Area Contributions](./01%20InfoWorks%20ICM/02%20SQL/01%20InfoWorks/0049%20-%20Calculate%20Runoff%20Area%20Contributions/)** - Automated catchment analysis
- **[Batch Plot Event Files](./01%20InfoWorks%20ICM/03%20Python/0001%20batch%20plot%20event%20file/)** - Visualize simulation results
- **[Isolation Trace](./04%20InfoWorks%20WS%20Pro/01%20Ruby/Isolation%20Trace/)** - Network connectivity analysis

## Understanding Script Types

### Ruby Scripts

Ruby scripts come in two flavors, each with distinct capabilities:

| Type | Naming | Runs From | Requirements | Best For |
|------|--------|-----------|--------------|----------|
| **UI Scripts** | `UI_script.rb` | Workgroup Client GUI | Standard license | Quick automation, interactive tasks |
| **Exchange Scripts** | `EX_script.rb` | Command line via `IExchange.exe` | Exchange license | Batch processing, headless automation |

#### Running Exchange Scripts

Use this template `.bat` file to execute Exchange scripts:

```batch
@ECHO OFF
SET script=EX_script.rb
SET version=2021.1
SET bit=64
IF %bit%==32 (SET "path=C:\Program Files (x86)")
IF %bit%==64 (SET "path=C:\Program Files")
"%path%\Innovyze Workgroup Client %version%\IExchange" "%~dp0%script%" ICM
```

**Customize:**
- `script` - Your Ruby script filename
- `version` - Your Workgroup Client version
- `bit` - Architecture (32 or 64)

### SQL Queries

Autodesk Water products use a specialized SQL dialect for powerful network operations:

**Capabilities:**
- Select objects based on complex criteria
- Update multiple fields simultaneously  
- Chain operations with multiple clauses
- Save as reusable Stored Queries

**Query Structure:**
```sql
SELECT WHERE condition1;
UPDATE SET field = value WHERE condition2;
DESELECT WHERE condition3;
```

## Contributing

We welcome contributions from the water modeling community!

### Share Your Scripts

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-script`)
3. Add your script following our [naming conventions](#understanding-script-types)
4. Include a README with description and usage examples
5. Submit a [Pull Request](https://github.com/innovyze/Open-Source-Support/pulls)

### Report Issues

Found a bug or have a suggestion? [Open an issue](https://github.com/innovyze/Open-Source-Support/issues) - we're here to help!

### Community Guidelines

- Be respectful and constructive
- Document your code clearly
- Test scripts before submitting
- Follow existing patterns and conventions

## Community

Join a thriving community of water infrastructure professionals:

- Share knowledge and best practices
- Ask questions and get expert help
- Collaborate on complex modeling challenges
- Learn from real-world implementation examples

**Together, let's advance the future of water infrastructure modeling!**

## Repository Structure

```
Open-Source-Support/
├── 01 InfoWorks ICM/
│   ├── 01 Ruby/
│   ├── 02 SQL/
│   └── 03 Python/
├── 02 InfoAsset Manager/
├── 03 ICMLive/
├── 04 InfoWorks WS Pro/
│   ├── 01 Ruby/
│   ├── 02 SQL/
│   └── 03 VBScript/
├── 05 InfoWater Pro/
│   └── 01 Python/
├── 06 XPSWMM/
│   └── 01 Tutorials/
└── Traffic-Analytics/
    └── Analytics Dashboard (auto-updated weekly)
```

## Important Notes

### Project Evolution

This repository is **growing organically** with the community. We may occasionally reorganize structure to improve usability. We'll minimize disruption, but please bookmark specific scripts rather than relying on deep links during early development.

### Liability & Support

- **Community-Driven**: Scripts are shared in good faith by Autodesk Support and community contributors
- **Open Source**: All code is transparent and available for review
- **Use at Own Risk**: Autodesk is not liable for unintended consequences
- **Not for Bespoke Projects**: Custom development requests should go through official Autodesk channels

### Script Quality

Scripts are typically developed for specific customer use cases. While functional, they may not be fully optimized. We encourage the community to:

- Suggest improvements via pull requests
- Report issues for enhancement
- Add documentation and examples
- Share your own optimizations

## Analytics

Curious about repository activity? Check out our [**live analytics dashboard**](https://innovyze.github.io/Open-Source-Support/) to see:

- Traffic trends and growth
- Community engagement metrics
- Historical data and patterns
- Popular content insights

---

<div align="center">

**Made with 💙 by the Autodesk Water community**

[View Dashboard](https://innovyze.github.io/Open-Source-Support/) • [Report Issue](https://github.com/innovyze/Open-Source-Support/issues) • [Exchange Docs](https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=Innovyze_Exchange_Introduction_ICM_introduction_html)

**Star this repo if you find it helpful!** ⭐

</div>
