import logging
import datetime
import os
import pandas as pd

FORMAT = '%(asctime)-15s %(lineno)s:  %(message)s'
logging.basicConfig(format=FORMAT, level=logging.DEBUG)


def read_hms_csv(csv_path, datetime_fld='datetime', date_format='%d%b%Y  %H%M'):
    """read the csv file into a dataframe, defaul csv format is
        # datetime,Node1,Node2,Node3
        # 01Jun2007  0000,0,0,0
        # 01Jun2007  0005,0.023,0.04,0.014
        # 01Jun2007  0010,0.107,0.17,0.065
        # 01Jun2007  0015,0.268,0.45,0.162

    Args:
        csv_path (str): path of the csv file
        datetime_fld (str, optional): date time field name. Defaults to 'datetime'.
        date_format (str, optional): date time format. Defaults to '%d%b%Y  %H%M'.

    Returns:
        pd.DataFrame: read the csv into a dataframe, 
        "hour": time passed since starting
        "dt": datetime object parsing the datetime string
    """
    df = pd.read_csv(csv_path)
    df['dt'] = df[datetime_fld].apply(lambda x: datetime.datetime.strptime(x, date_format))
    t0 = min(df['dt'].values)
    df['hour'] = df['dt'].apply(lambda x: (x - t0).days * 24 + (x - t0).seconds / 3600.0)
    return df


# def long_table(csv_path, out_csv_path, datetime_fld='datetime', date_format='%d%b%Y  %H%M', time_column='dt'):
#     """save a wide format table to a long format

#     Args:
#         csv_path (str): wide format csv file
#         out_csv_path (str): csv file to be saved
#         datetime_fld (str, optional): date time field name. Defaults to 'datetime'.
#         date_format (str, optional): date time format. Defaults to '%d%b%Y  %H%M'.
#         time_column (str, optional): field used for time stamp. Defaults to 'dt', the date time object, 'hour' is another option.
#     """
#     df = read_hms_csv(csv_path, datetime_fld, date_format)
#     value_vars = [x for x in df.columns if x not in [datetime_fld,'hour','dt']]
#     pd.melt(df, id_vars=time_column, value_vars=value_vars, var_name='STATION', value_name='FLOW').sort_values(['STATION', 'dt']).to_csv(out_csv_path, index=False)

def hms_csv_to_xpx(csv_path, xpx_path, datetime_fld='datetime', date_format='%d%b%Y  %H%M'):
    """convert hydrograph for each node into xpx file for XPSWMM
    Example csv:
         datetime,Node1,Node2,Node3
         01Jun2007  0000,0,0,0
         01Jun2007  0005,0.023,0.04,0.014
         01Jun2007  0010,0.107,0.17,0.065
         01Jun2007  0015,0.268,0.45,0.162
    Example xpx:
        DATA INQ "0" 0 1 1
        DATA TEO "0" 0 7231 0.0 0.0...
        DATA QCARD "0" 0 7231 0....

    Args:
        csv_path (str): path to the HECHMS flow csv file
        xpx_path (str): path to the new xpx file converted from the csv path
        datetime_fld (str, optional): date time field name. Defaults to 'datetime'.
        date_format (str, optional): date time format. Defaults to '%d%b%Y  %H%M'.
    """
    df = read_hms_csv(csv_path, datetime_fld, date_format)
    hours = df['hour'].values
    ct = len(hours)
    hours_list = ' '.join([str(x) for x in hours])
    with open(xpx_path, 'w') as o:
        for fld in df.columns:
            if fld in ['dt', datetime_fld, 'hour']:
                pass
            else:
                values = df[fld].values
                values = ' '.join([str(x) for x in values])

                o.write('DATA INQ "%s" 0 1 1\n' % fld)
                o.write('DATA TEO "%s" 0 %s %s\n' % (fld, ct, hours_list))
                o.write('DATA QCARD "%s" 0 %s %s\n' % (fld, ct, values))

def long_table(csv_path, out_csv_path, datetime_fld='datetime', date_format='%d%b%Y  %H%M', time_column='dt', value_name='FLOW'):
    """create a long table in the format
       DATE,TIME,FLOW,STATION
       06/01/07,00:00,0.0,Node1
       06/01/07,00:05,0.023,Node1

    Args:
        csv_path (str): HECHMS csv
        out_csv_path (str): csv file with the long format
        datetime_fld (str, optional): date time field name. Defaults to 'datetime'.
        date_format (str, optional): date time format. Defaults to '%d%b%Y  %H%M'.
        time_column (str, optional): field used for time stamp. Defaults to 'dt', the date time object, 'hour' is another option.
        value_name (str, optional): the value field. Defaults to 'FLOW'.
    """
    df = read_hms_csv(csv_path, datetime_fld, date_format)
    value_vars = [x for x in df.columns if x not in [datetime_fld,'hour','dt']]
    df2 = pd.melt(df, id_vars=time_column, value_vars=value_vars, var_name='STATION', value_name=value_name).sort_values(['STATION', 'dt'])
    df2['DATE'] = df2.apply(lambda x: x['dt'].strftime('%m/%d/%Y'), axis=1)
    df2['TIME'] = df2.apply(lambda x: x['dt'].strftime('%H:%M'), axis=1)
    df2.loc[:, ['DATE', 'TIME', value_name, 'STATION']].to_csv(out_csv_path, index=False)

def gauged_inflow_xpx(xpx_path, long_csv_path, file_format, station_field='STATION'):
    """
    Create xpx file which will add the gauged flow for the list of node.
    Args:
        csv_path (str): path to the gauged inflow csv file
        node_name_field: the column name in the csv file for the node (station)
        xpx_path (str): path to the new xpx file
        file_format (str): the gauged csv file format name used in XPSWMM model
    """

    tmp = """DATA UDFS_FILE "{node}" 0 1 "{file}" 
DATA R_UDFS_FMTNAME "{node}" 0 1 "{file_format}" 
DATA GINFLOW "{node}" 0 1 1
DATA UDFS_STN "{node}" 0 1 "{node}"
"""
    df = pd.read_csv(long_csv_path)
    long_csv_path = os.path.abspath(long_csv_path)
    with open(xpx_path, 'w') as o:
        for node in df[station_field].unique():
            o.write(tmp.format(node=node, file=long_csv_path, file_format=file_format))
            logging.info('write line for node: %s', node)
    logging.info('xpx saved to: %s', xpx_path)
