# Summary:
The provided VBA macro script is a key tool in transitioning from InfoSewer or InfoSWMM models to InfoWorks ICM. It automates the conversion of diurnal pattern data into a format that InfoWorks ICM can recognize and use.

The script starts by prompting the user to specify a file name and the input and output directories. Once these inputs are provided, the script processes a specific "PATNDATA.csv" file located in the input directory.

The processed data is then manipulated and structured appropriately, and subsequently pasted into either the "Trade waste" or "Waste water" sheet, depending upon which subroutine is being executed.

Finally, the manipulated data is saved as a new CSV file in the user-specified output directory. This automated process significantly simplifies and streamlines the data conversion task, making the transition from InfoSewer or InfoSWMM to InfoWorks ICM more efficient.