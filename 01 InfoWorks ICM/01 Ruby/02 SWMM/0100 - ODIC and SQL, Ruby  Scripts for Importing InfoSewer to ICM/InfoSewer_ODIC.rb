# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step1_InfoSewer_Node_csv.cfg', 'Node.csv'],
    ['Node', 'Step1a_InfoSewer_Manhole_csv.cfg', 'manhole.csv'],
    ['Subcatchment', 'Step1b_InfoSewer_Subcatchment_Manhole_csv.cfg', 'Node.csv'],
    ['Conduit', 'Step2_InfoSewer_Link_csv.cfg', 'Link.csv'],
    ['Node', 'Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Conduit', 'Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg', 'pipehyd.csv'],
    ['Subcatchment', 'Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Pump', 'Step5_InfoSewer_pump_curve_pumphyd_csv.cfg', 'pumphyd.csv'],
    ['Pump', 'Step6_InfoSewer_pump_control_control_csv.cfg', 'control.csv'],
    ['Node', 'Step8_Infosewer_wetwell_wwellhyd_csv.cfg', 'wwellhyd.csv'],
    ['RTK Hydrograph', 'Step9_rdii_hydrograph_csv.cfg', 'Hydrograph.csv'],
    # MH DWF and Pipe Hydraulics 
    ['Subcatchment','Step10_InfoSewer_subcatchment_dwf_mhhyd_scenario.cfg', 'mhhyd.csv'],
    ['Conduit','Step11_InfoSewer_pipehyd_scenario.cfg', 'pipehyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
