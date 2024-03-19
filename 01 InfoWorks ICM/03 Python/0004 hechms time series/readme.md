---
title: Batch Importing Time Series
---

# Introduction

In the United States, HEC-HMS is widely used to generate the hydrographs from subcatchments when building stormwater and flood control models. Then the hydrographs are routed in a hydraulics package such as InfoWorks ICM and XPSWMM.

For models with hundreds of subcatchments, copying hydrograph manually can be very tedious. In this article, we’ll go through a few examples of converting the hydrographs from a csv file into several commonly used file formats.

# Install python

If you don’t have python on your computer, Anaconda makes installing python easy. Here is the [<u>download link</u>](https://www.anaconda.com/products/individual#windows). Either 64-bit or 32-bit should work.

# Save HEC-HMS time series to CSV

This csv file can be easily created from HEC-HMS using HEC-DSSVue. Open the exported excel file and remove the extra rows and columns.

<img src="./media/image1.png" style="width:6.5in;height:4.37222in" alt="A screenshot of a spreadsheet Description automatically generated" />

# Processing the HEC-HMS CSV file

The format is shown in the figure, each column is a hydrograph for a node. The header should match node names exactly. The first column is the time stamp, and it should be called datetime and the format should look like the following.

<img src="./media/image2.png" style="width:2.136in;height:1.84867in" alt="A screenshot of a table Description automatically generated" />

Typical processing of time series data includes,

- Use a different date time format for time stamp

- Calculate the time passed since a starting point for each row

- Convert between long and wide format

## Use a different date time format for time stamp

There are many formats to choose from for date time,

- Mon 01 Jan 2001, 10:20AM (%a %d %b %Y, %I:%M%p)

- 01Jan2001 1020 (%d%b%Y %H%M)

- 01/01/2001 10:20 (%m/%d/%Y %H:%M)

- 2001-01-01 10:20:36 (%Y-%m-%d %H:%M:%S)

Refer to the [python documentation](https://docs.python.org/3/library/datetime.html#strftime-strptime-behavior) for more details on the format codes.

datetime.strptime('31/01/22 23:59:59.999999','\*\*%d\*\*/%m/%y %H:%M:%S.\*\*%f\*\*')

datetime.datetime(2022, 1, 31, 23, 59, 59, 999999).strftime('\*\*%a\*\* \*\*%d\*\* %b %Y, %I:%M%p')

\#'Mon 31 Jan 2022, 11:59PM'

## Calculate the time passed since a starting point for each row

Sometimes, instead of a time stamp, the time passed since the beginning of the simulation is required to define a time series. For example, XPSWMM inflow, rainfall requires this format.

<img src="./media/image3.png" style="width:1.99742in;height:3.15245in" alt="A screenshot of a computer Description automatically generated" />

## Long vs wide format

Time series are commonly arranged in two formats, the long and wide format.

- The long format saves each time series as a column.

- The wide format saves all the values in the same column and adds a “station” column so that you can filter the time series.

<img src="./media/image4.png" style="width:4.92848in;height:2.64775in" alt="A screenshot of a spreadsheet Description automatically generated" />

# Run the scripts

Download the “004 HECHMS TIME SERIES” folder from [<u>Github</u>](https://github.com/innovyze/Open-Source-Support/tree/main/01%20InfoWorks%20ICM/03%20Python/004%20hechms%20time%20series). If you are using Anaconda, start “spyder”. Open hms_csv_tools.py and run the script.

<img src="./media/image5.png" style="width:1.81589in;height:3.05456in" alt="A screenshot of a computer Description automatically generated" /> <img src="./media/image6.png" style="width:3.91513in;height:1.71938in" alt="A screenshot of a computer program Description automatically generated" />

Go to the “data” folder to review the results,

- hms.csv: the input HECHMS time series

<img src="./media/image7.png" style="width:1.47in;height:0.69in" alt="A screenshot of a table Description automatically generated" />

- hms2.csv: add “dt” and “hour” to the hms.csv

<img src="./media/image8.png" style="width:2.42in;height:0.71in" alt="A screenshot of a computer Description automatically generated" />

You can import flows from this file into InfoWorks ICM,

<img src="./media/image9.png" style="width:3.66405in;height:2.09821in" alt="A screenshot of a computer Description automatically generated" />

<img src="./media/image10.png" style="width:4.0914in;height:3.68357in" alt="A screenshot of a computer Description automatically generated" />

- long.csv: the long format

<img src="./media/image11.png" style="width:1.32in;height:0.99in" alt="A screenshot of a computer Description automatically generated" />

- inflow.xpx: XPSWMM inflow time series in xpx format

<img src="./media/image12.png" style="width:5.02242in;height:3.19052in" alt="A screenshot of a computer Description automatically generated" />

- gauged.xpx: XPSWMM using gauged inflow, getting data from external csv file.

<img src="./media/image13.png" style="width:3.56381in;height:3.41532in" alt="A screenshot of a computer Description automatically generated" />

<img src="./media/image14.png" style="width:3.33955in;height:1.13929in" alt="A screenshot of a computer Description automatically generated" />

Importing this xpx file will add the references to the external csv to each node.

<img src="./media/image15.png" style="width:4.11796in;height:1.24622in" alt="A screenshot of a computer Description automatically generated" />
