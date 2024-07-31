#Below script will read the data from the csv file which will contaian three columns
#First column will be manhole id, second column will be system type and third column will be manhole depth
#Script will filter data where system type is "Storm" and manhole depth is greater than 1

import os
import pandas as pd

# Get the current script's folder path
script_folder_path = os.path.dirname(os.path.abspath(__file__))

# Read the CSV file
input_csv_file_path = os.path.join(script_folder_path, 'manhole.csv')
#Read the csv file and store it in a dataframe, first row of csv is header
df = pd.read_csv(input_csv_file_path)

# Filter the data, with on mandole id
filtered_df = df[(df['System Type'] == 'storm') & (df['Depth'] > 0.5)]
#Filtered df with only mandole id
filtered_df = filtered_df[['Manhole ID']]

# Export the filtered data to a new CSV file
filtered_csv_file_path = os.path.join(script_folder_path, 'filtered_data.csv')
filtered_df.to_csv(filtered_csv_file_path, index=False)
