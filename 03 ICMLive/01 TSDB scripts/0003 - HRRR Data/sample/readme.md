# Introduction

This sample shows how to setup a scheduled task to download real-time
hourly spatial rainfall forecast for the next 18 hours from the [NOAA
HRRR](https://rapidrefresh.noaa.gov/hrrr/) site. NOAA uploads the
forecast for the next 18 hours every hour consisting of 18 files. This
enhanced version will run every 15 minutes to make sure all the 18 files
are downloaded for each hour. If you don’t need to continuously download
the data, you can manually run the script without setting up a scheduled
task.

Before getting started you’ll need to have the following,

-   A server that you can setup a scheduled task

-   The bounding box of the area for the rainfall data

-   Create the folders for the scripts and the downloaded files

-   (Optional) for automated modeling, setup a scheduled task to run the
    script every 15 minutes

-   Setup the spatial database for loading the HRRR data

-   (Optional) Setup the data loader to load the downloaded data into
    the system every 30 minutes

The main challenge with HRRR workflow is that ICMLive requires all the
data files to be downloaded for each forecast before it can be imported.
However, the time when all the files are ready to be downloaded can
change from hour to hour. Downloading the file over the Internet can
also pose some connection issues. Therefore, if we download the data
only once, we might not be able to get the full dataset.

To overcome these challenges, this script should be scheduled to run
every 15 minutes starting at 10min of each hour. This way, we try to
download the data 4 times at 10, 25, 40, 55min each hour. This should
overcome most of the issues if we only try to download the data once an
hour.

# Install the script

The script only uses PowerShell script and batch files, any windows
computer should support it.

1.  Create a script folder, and data folder. In this example, both under
    the sample folder

<img src="media/image1.png" style="width:1.61438in;height:1.39566in"
alt="Graphical user interface, application Description automatically generated" />

2.  Copy hrrr.bat and hrrr.ps1 to the script folder

<img src="media/image2.png" style="width:1.43732in;height:1.30192in"
alt="Graphical user interface, application Description automatically generated" />

3.  Edit hrrr.bat as shown below

<!-- -->

1)  Setup the bounding box, you can get it in Google Maps by right click
    on the map, make sure there is no space before and after the “=”
    sign

> <img src="media/image3.png" style="width:2.82815in;height:3.02662in"
> alt="Diagram Description automatically generated with medium confidence" />

2)  Update the folder where the hrrr files will be downloaded, make sure
    there are two slashes at the end

<img src="media/image4.png" style="width:6.5in;height:2.55in"
alt="Text Description automatically generated" />

4.  Run the \*.bat file, you should see files starts to download in the
    data folder

> <img src="media/image5.png" style="width:2.33304in;height:2.11432in"
> alt="Graphical user interface, text Description automatically generated" />

5.  Check the log file, as shown below, it shows the files that are
    successfully downloaded, and the one that are not downloaded yet

> <img src="media/image6.png" style="width:6.5in;height:1.78194in"
> alt="Text Description automatically generated with low confidence" />
>
> When all the 18 files are downloaded, a text file with the prefix for
> the forecast will be created.
>
> <img src="media/image7.png" style="width:2.09349in;height:1.87477in"
> alt="Text Description automatically generated" />

6.  Setup a task scheduler

<img src="media/image8.png" style="width:1.90601in;height:0.73949in"
alt="A picture containing text, sign Description automatically generated" />

<img src="media/image9.png" style="width:4.73585in;height:3.59692in"
alt="Graphical user interface, application Description automatically generated" />

<img src="media/image10.png" style="width:4.7817in;height:3.82536in"
alt="Graphical user interface, application Description automatically generated" />

# Load the HRRR files into a TSDB

1.  Define the projection in GeoPlan

<img src="media/image11.png" style="width:2.59343in;height:0.87489in"
alt="Graphical user interface, text, application Description automatically generated" />

<img src="media/image12.png" style="width:5.03062in;height:3.12461in"
alt="Graphical user interface, text, application, email Description automatically generated" />

2.  Verify the projection using Google Maps

<img src="media/image13.png" style="width:6.5in;height:3.39097in"
alt="Diagram Description automatically generated" />

<img src="media/image14.png" style="width:6.5in;height:3.0875in"
alt="Diagram Description automatically generated" />

3.  Zoom to the extent for the rainfall (if you only need to load the
    rainfall for part of the downloaded HRRR files.)

4.  Create a spatial time series database

<img src="media/image15.png" style="width:4.03075in;height:2.28096in"
alt="Graphical user interface, application Description automatically generated" />

5.  Setup the TSDB

<img src="media/image16.png" style="width:6.5in;height:5.68333in"
alt="A picture containing map Description automatically generated" />

1.  Give it a name

2.  Depending how far into the future you need to run the model, maximum
    is 18.

3.  Select a sample file from the data folder

4.  HRRR uses UTC time

5.  Select the projection of the model network

6.  If you need to crop the data, check this option, and the easiest way
    to do it is to zoom to the area in the GeoPlan, TSDB will
    automatically pick up the coordinates.

7.  The conversion for imperial unit, and time interval is 1hr

8.  If you are using dataloader, setup the update schedule. It depends
    on how often you run the forecast simulation.

<img src="media/image17.png" style="width:5.64513in;height:3.9995in"
alt="Graphical user interface, application Description automatically generated" />

6.  Review the results

<!-- -->

1.  Open the network

2.  Turn on the radar cell

> <img src="media/image18.png" style="width:2.08307in;height:2.99962in"
> alt="Graphical user interface, application Description automatically generated" />
>
> <img src="media/image19.png" style="width:4.11407in;height:5.59305in"
> alt="Graphical user interface, application, website Description automatically generated" />

7.  Drag the TSDB into the GeoPlan

<!-- -->

1.  Graph the data to get some sense of the rainfall events.

<img src="media/image20.png" style="width:6.5in;height:4.94722in"
alt="A picture containing chart Description automatically generated" />

2.  Review the rainfall event

<img src="media/image21.png" style="width:6.5in;height:3.49167in"
alt="Graphical user interface, application Description automatically generated" />

1.  Select a forecast

2.  Use arrow key to move through the forecast

3.  See the rainfall in the GeoPlan
