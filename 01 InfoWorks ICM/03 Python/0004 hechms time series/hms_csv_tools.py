import hms_csv

if __name__ == '__main__':
    # for help: https://medium.com/@mel.meng.pe/batch-hydrographs-into-xpswmm-a9303df7a46b
    # the hydrograph csv file path, e.g. c:\temp\hydrograph.csv
        # first column should be datetime and the date format is: 01Jun2007  0010
        # other columns should have the node name in XPSWMM/XPSTORM as the header
        # datetime,Node1,Node2,Node3
        # 01Jun2007  0000,0,0,0
        # 01Jun2007  0005,0.023,0.04,0.014
        # 01Jun2007  0010,0.107,0.17,0.065
        # 01Jun2007  0015,0.268,0.45,0.162
    
    #add dt and hour columns to the csv
    #example using full path
    #csv_path = r'C:\temp\hms.csv'
    csv_path = './data/hms.csv'
    csv2_path = './data/hms2.csv' # the csv file with dt and hour columns
    hms_csv.read_hms_csv(csv_path).to_csv(csv2_path, index=False)

    #save csv as long table
    out_csv_path = './data/long.csv'
    hms_csv.long_table(csv_path, out_csv_path, datetime_fld='datetime', date_format='%d%b%Y  %H%M', time_column='dt')

    #create the gauged inflow xpx 
    xpx_path = './data/gauged.xpx'
    long_csv_path = r"C:\tmp\gauged\long.csv" #'./data/long.csv'
    file_format = 'inflow'
    hms_csv.gauged_inflow_xpx(xpx_path, long_csv_path, file_format, station_field='STATION')
    
    #convert the csv file to xpx file, it imports as inflows for nodes
    #example using full path
    #csv_path = r'C:\temp\hms.csv'
    csv_path = './data/hms.csv'
    xpx_path = './data/inflow.xpx' # the xpx file to be created
    hms_csv.hms_csv_to_xpx(csv_path, xpx_path, datetime_fld='datetime', date_format='%d%b%Y  %H%M')

