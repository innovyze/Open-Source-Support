# ICM SWMM vs ICM files 
#  This function reads CSV files from ICM SWMM and ICM and compares them.
#  The CSV files are generated from the ICM SWMM and ICM models using the
#  "Export Results to CSV" function in the ICM SWMM and ICM models.
#  The CSV files are compared by comparing the values in the "Value" column.
#  The CSV files are assumed to have the same number of rows and the same
#  column headers.

require 'csv'

def compare_icm_swmm_icm_files(icm_swmm_csv_file, icm_csv_file)
  # The CSV files are assumed to have the same number of rows and the same
  # column headers.
  icm_swmm_csv = CSV.read(icm_swmm_csv_file)
  icm_csv = CSV.read(icm_csv_file)
  # The CSV files are assumed to have the same number of rows and the same
  # column headers.
  icm_swmm_csv.each_with_index do |icm_swmm_row, index|
    icm_row = icm_csv[index]
    # Compare the values in the "Value" column.
    if icm_swmm_row[1] != icm_row[1]
      return false
    end
  end
  return true
end