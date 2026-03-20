import pandas as pd
import os

# # Timestep Log File to Excel
#
# The timestep log is very useful When debugging an InfoWorks ICM model, however, the log file usually will have thousands of lines and extracting the useful information can be a challenge.
#
# Using the code block below, the count tables showing the nodes and links with trouble in calculation are exported into an Excel spreadsheet. Each tab is a table ordered with the object with the highest number of count of iterations.
#
# For example, the tabs are named as "line no-Table name"
#
# - 93-Unconverged link depth
# - 98-Unconverged nodes coun
# - 1084-Link depth fail coun
#

def token(l):
    if ' counts:' in l:
        return ('counts header', l.strip())
    else:
        return ('line', l)
    

def get_table(log_path):
    ct = 0
    with open(log_path) as f:
        
        tables = {}
        table_name = None
        for l in f:
            ct += 1
            a, b = token(l)
            if a == 'counts header':
                b = '{}-{}'.format(ct, b.replace(':', ''))[:25]
                tables[b] = []
                if table_name is None:
                    table_name = b
            elif a == 'line':
                if l =='\n':
                    table_name = None
                else:
                    if table_name:
                        tables[table_name].append(l.strip().rsplit(' ', 1)) # using rsplit in case there is space in ID
                # print(l)
        return tables

def process_tables(tables):
    results = {}
    for fld in tables:
        results[fld] = pd.DataFrame(tables[fld], columns=['ID', 'count'])
        results[fld]['count'] = pd.to_numeric(results[fld]['count'])
    return results

def save_tables(tables, excel_path):
    with pd.ExcelWriter(excel_path) as writer:
        for fld in tables:
            tables[fld].sort_values(by=['count'], ascending=False).to_excel(writer, sheet_name=fld, index=False)


def log_to_excel(log_path, excel_path):
    tables = process_tables(get_table(log_path))
    save_tables(tables, excel_path)

# step 1 turn on timestep log in the RUN
# step 2 run the simulation
# step 3 export the log to a file
# step 4 set up the log path, and the excel_path and run this cell
log_path = './../data/sim.log'
excel_path = log_path.replace('.log', '.xlsx')
log_to_excel(log_path, excel_path)

# Here is an example to read the tables into a variable
tables = process_tables(get_table(log_path))
for fld in tables:
    print(fld)
    print(tables[fld].head())

import math

pi = math.pi

a = pi*(0.667/2)**2

q = 1.9983 #mgd
q = 1.547*q #cfs

v = q/a

v
