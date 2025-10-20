# 📊 Traffic Data Analytics Dashboard

An interactive, real-time analytics dashboard for tracking GitHub repository traffic using D3.js visualization.

## 🚀 Live Dashboard

**[View Live Dashboard →](https://ubiquitous-telegram-9qkrqrg.pages.github.io/)**

![Traffic Analytics Preview](./docs/preview-placeholder.png)

*Interactive charts showing repository views and clone trends over time*

## ✨ Features

- **📈 Interactive Time Series Charts** - Visualize total and unique views/clones with smooth animations
- **🎯 Real-Time Statistics** - Key metrics including total views, unique visitors, and peak traffic days
- **🕒 Flexible Time Ranges** - View data for 30 days, 90 days, 1 year, or all time
- **💫 Responsive Design** - Works beautifully on desktop, tablet, and mobile devices
- **🎨 Modern UI** - Glassmorphism design with gradient colors and smooth transitions
- **📊 Hover Tooltips** - See detailed data points by hovering over the charts

## 📁 Project Structure

```
Traffic-Data/
├── index.html              # Main dashboard page
├── README.md               # This file
├── assets/
│   ├── css/
│   │   └── styles.css      # All styling
│   └── js/
│       ├── app.js          # Main application logic
│       ├── chart.js        # Chart rendering module
│       ├── config.js       # Configuration constants
│       ├── dataLoader.js   # Data loading utilities
│       └── utils.js        # Helper functions
├── data/
│   ├── views.csv           # Views data (auto-updated weekly)
│   ├── clones.csv          # Clones data (auto-updated weekly)
│   └── archive/            # Historical/archived data files
├── docs/
│   └── generate-preview.html  # Preview image generator
└── .github/
    └── workflows/
        └── workflow.yml    # GitHub Actions automation
```

## 🔄 Automated Data Collection

This repository uses GitHub Actions to automatically collect traffic data:

- **Schedule**: Runs weekly (every Sunday at 23:55 UTC)
- **Action**: Uses [repository-traffic-action](https://github.com/innovyze/repository-traffic-action)
- **Updates**: Automatically commits new data to `data/views.csv` and `data/clones.csv`
- **Dashboard**: Automatically displays updated data on page refresh

## 🛠️ Technology Stack

- **D3.js v7** - Data visualization library
- **Vanilla JavaScript** - No frameworks, pure ES6 modules
- **CSS3** - Modern styling with glassmorphism effects
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
   git clone https://github.com/moreird/Traffic-Data.git
   cd Traffic-Data
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

To generate a preview image for the README:

1. Open `docs/generate-preview.html` in your browser (via local server)
2. Wait for the chart to render (shows last 3 months of data)
3. Take a screenshot or use browser dev tools to capture the image
4. Save as `docs/preview-placeholder.png`

## 📝 License

This project is open source and available for use.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

---

**Last Updated**: Automatically via GitHub Actions  
**Dashboard Version**: 1.0.0

