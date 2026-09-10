# 📊 Traffic Data Analytics Dashboard

An interactive, real-time analytics dashboard for tracking GitHub repository traffic using D3.js visualization.

## 🚀 Live Dashboard

View the dashboard by opening `index.html` in a web browser (requires local web server - see Local Development section below).

![Traffic Analytics Preview](./assets/images/preview.png)

*Interactive charts showing repository views and clone trends over time*

## ✨ Features

- **📈 Interactive Time Series Charts** - Visualize total and unique views/clones with smooth animations
- **🎯 Real-Time Statistics** - Key metrics including total views, unique visitors, and peak traffic days
- **🕒 Flexible Time Ranges** - View data for 30 days, 90 days, 1 year, or all time
- **💫 Responsive Design** - Works beautifully on desktop, tablet, and mobile devices
- **🎨 Autodesk-aligned UI** - Black/white surfaces, Artifakt type stacks, and restrained tertiary chart colors
- **📊 Hover Tooltips** - See detailed data points by hovering over the charts

## 📁 Project Structure

```
Open-Source-Support/
├── .github/
│   └── workflows/
│       └── workflow.yml    # GitHub Actions automation
└── Traffic-Analytics/      # Traffic Analytics Dashboard
    ├── index.html          # Main dashboard page
    ├── README.md           # This file
    ├── assets/
    │   ├── css/
    │   │   └── styles.css  # All styling
    │   └── js/
    │       ├── app.js          # Main application logic
    │       ├── chart.js        # Chart rendering module
    │       ├── config.js       # Configuration constants
    │       ├── dataLoader.js   # Data loading utilities
    │       └── utils.js        # Helper functions
    ├── data/
    │   ├── views.csv       # Views data (auto-updated weekly)
    │   └── clones.csv      # Clones data (auto-updated weekly)
    └── docs/
        └── generate-preview.html  # Preview image generator
```

## 🔄 Automated Data Collection

This repository uses GitHub Actions to automatically collect traffic data:

- **Schedule**: Runs weekly (every Sunday at 23:55 UTC)
- **Action**: Uses [repository-traffic-action](https://github.com/innovyze/repository-traffic-action)
- **Updates**: Automatically commits new data to `Traffic-Analytics/data/views.csv` and `Traffic-Analytics/data/clones.csv`
- **Dashboard**: Automatically displays updated data on page refresh

## 🛠️ Technology Stack

- **D3.js v7** - Data visualization library
- **Vanilla JavaScript** - No frameworks, pure ES6 modules
- **CSS3** - Autodesk brand tokens with solid surfaces and responsive layout
- **GitHub Pages** - Free hosting
- **GitHub Actions** - Automated data collection

## 📊 Data Sources

Traffic data is collected from GitHub's Traffic API:

- **Views**: Daily total and unique page views
- **Clones**: Daily total and unique repository clones
- **History**: Data available since March 2021

## 🚀 Local Development

To run the dashboard locally:

1. Clone the repository:
   ```bash
   git clone https://github.com/moreird/Open-Source-Support.git
   cd Open-Source-Support/Traffic-Analytics
   ```

2. Start a local web server (required for loading CSV files):
   ```bash
   # Using Python 3
   python -m http.server 8000
   
   # Or using Node.js
   npx http-server
   ```

3. Open your browser to `http://localhost:8000`

## 📸 Generating Preview Images

To regenerate README and social preview assets:

1. Start a local web server from the repo root (CSV loading requires HTTP):
   ```bash
   python -m http.server 8765 --bind 127.0.0.1
   ```
2. Open `http://127.0.0.1:8765/docs/generate-preview.html`, wait for the chart to render, and capture `#preview` as `assets/images/preview.png`.
3. Open `http://127.0.0.1:8765/docs/generate-og-card.html`, wait for the chart to render, and capture `#ogCard` at 1200×630 as `assets/brand/og-card.png`.
4. Both generator pages use the shared `assets/css/styles.css` palette and typography.

## 📝 License

This project is open source and available for use.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

---

**Last Updated**: Automatically via GitHub Actions  
**Dashboard Version**: 1.0.0

