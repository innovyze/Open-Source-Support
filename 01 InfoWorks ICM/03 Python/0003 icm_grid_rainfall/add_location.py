import csv
def parse_line(line):
    """
    below is an example of a line of gage data,
    "REGION=5,622593.573099,162478.222631,621601.116681,162654.635489,621780.655846,163630.062159,622773.118767,163453.650017,622593.573099,162478.222631;LOCATION=2323,233423;"
    find all the x, y pairs of the region, then calculate the center of the region and add ;LOCATION=X, Y; to the end of the line
    Args:
        line (str): REGION=XXXX 

    Returns:
        str: the line with location=x,y added.
    """
    
    line = line.replace('"', '')
    xy = [float(x) for x in line.split(';')[0].replace('REGION=', '').split(',')]
    ct = int(xy[0])
    xy = xy[1:]
    # print(ct)
    # print(xy)
    xs =[xy[2*i] for i in range(ct)]
    ys =[xy[2*i + 1] for i in range(ct)]
    x = sum(xs)/ct
    y = sum(ys)/ct
    
    return "{}LOCATION={},{};".format(line, x, y)

def add_location(input_csv, updated_csv):
    """add location=x, y to each profile and save the csv file

    Args:
        input_csv (str): ICM rainfall csv file, with region for each profile without location information
        updated_csv (str): ICM rainfall csv file with center of region added
    """
    with open(updated_csv, 'w') as f:
        with open(input_csv) as o:
            for line in o:
                if "REGION=" in line:
                    for l in csv.reader([line]):
                        c2 = parse_line(l[2])
                        line = '{},{},"{}"\n'.format(l[0], l[1], c2)
                f.write(line)
                
# csv exported from InfoWorks ICM without labels
input_csv = './data/gridded_no_location.csv'
# import this csv file below back to InfoWorks ICM which will show labels
updated_csv = './data/gridded_with_location.csv'
add_location(input_csv, updated_csv)