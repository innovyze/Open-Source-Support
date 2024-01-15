# Timestep_log_file_reader

The timestep log is very useful When debugging an InfoWorks ICM model, however, the log file usually will have thousands of lines and extracting the useful information can be a challenge.

The “timestep_log_file_reader.ipynb” can extract the count tables showing the nodes and links with trouble in calculation into an Excel spreadsheet.

Here are a few example tabs,

- 93-Unconverged link depth

- 98-Unconverged nodes coun

- 1084-Link depth fail coun

The tab name starts with the line no, then the name of that table.

<img src="./media/image1.png" style="width:6.5in;height:2.00417in" alt="A screenshot of a computer Description automatically generated" />

The first few tables are for initializations, and the following tables are for the simulation.

To use this tool,

- step 1 turn on timestep log in the RUN

<img src="./media/image2.png" style="width:6.5in;height:3.80278in" alt="A screenshot of a computer Description automatically generated" />

- step 2 run the simulation

- step 3 export the log to a file

<img src="./media/image3.png" style="width:3.07253in;height:0.93738in" alt="A screenshot of a computer Description automatically generated" />

<img src="./media/image4.png" style="width:2.69758in;height:1.51023in" alt="A screenshot of a computer results Description automatically generated" />

<img src="./media/image5.png" style="width:2.59343in;height:1.65604in" alt="A screenshot of a computer screen Description automatically generated" />

- step 4 set up the log path, and the excel_path in the notebook and run the cell

<img src="./media/image6.png" style="width:4.16082in;height:1.77254in" alt="A screen shot of a computer code Description automatically generated" />

You will have a spreadsheet with all the count tables, and ordered by the count.

<img src="./media/image7.png" style="width:5.12436in;height:2.24972in" alt="A screenshot of a computer Description automatically generated" />
