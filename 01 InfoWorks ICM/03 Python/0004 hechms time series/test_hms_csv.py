import hms_csv
import pandas as pd

# # HECHMS Time Series
#
# Time series exported from HECHMS can be saved as CSV file
#
# ```
# datetime,Node1,Node2,Node3
# 01Jun2007  0000,0,0,0
# 01Jun2007  0005,0.023,0.04,0.014
# 01Jun2007  0010,0.107,0.17,0.065
# 01Jun2007  0015,0.268,0.45,0.162
# ```
#
# We'll go through a few examples on how to process this csv file.

# # Date Time Format
#
# Refer to [python doc](https://docs.python.org/3/library/datetime.html#strftime-and-strptime-behavior) for more information on changing the format for date and time.

import datetime

t = datetime.datetime(2001, 1, 1, 10, 20, 36)
for f in ['%a %d %b %Y, %I:%M%p', '%d%b%Y  %H%M', '%m/%d/%Y %H:%M', '%Y-%m-%d %H:%M:%S']:
    print('{}  ({})'.format(t.strftime(f), f))


# read the CSV file
csv_path = './data/hms.csv'
df = hms_csv.read_hms_csv(csv_path, datetime_fld='datetime', date_format='%d%b%Y  %H%M')
print(df)

df.plot.scatter(x='dt', y='Node1');

df.plot.scatter(x='hour', y='Node1');

# # Export as inflow in XPX format 
# For XPSWMM, you can export the data as inflow time series with hour/flow pairs.

xpx_path = './data/inflow.xpx'
hms_csv.hms_csv_to_xpx(csv_path, xpx_path, datetime_fld='datetime', date_format='%d%b%Y  %H%M')

with open(xpx_path) as f:
    for l in f:
        print(l)

# # Long table format
#
# A commonly used format is long format.

 #save csv as long table
out_csv_path = './data/long.csv'
hms_csv.long_table(csv_path, out_csv_path, datetime_fld='datetime', date_format='%d%b%Y  %H%M', time_column='dt')
df = pd.read_csv(out_csv_path)

df

# # Gagued Flow XPX

#create the gauged inflow xpx 
xpx_path = './data/gauged.xpx'
long_csv_path = r"C:\tmp\gauged\long.csv" #'./data/long.csv'
file_format = 'inflow'
hms_csv.gauged_inflow_xpx(xpx_path, long_csv_path, file_format, station_field='STATION')

i = 0
with open(xpx_path) as f:
    for l in f:
        i += 1
        print(l)
        if i > 5: break
