require 'date'
require 'csv'
require 'matrix'

net = WSApplication.current_network
result_type = 'mcpl1dis'
file_dir = WSApplication.folder_dialog 'Select a folder for results',  true
file_name = file_dir + '\\' + 'project_x_' + result_type + '.csv'

link = net.row_objects('hw_1d_results_point')
timesteps = net.list_timesteps
n = net.timestep_count
k = link.length

results2 = Array.new(k+1){Array.new(n+1)}
results2[0]=timesteps
q = 0
for i in 1..link.length
    dum=link[q]
    results2[i] = dum.results(result_type)
    q = q+1
end
results3 = results2.transpose()

linkname = Array.new(k+1){Array.new(1)}
q = 1
for i in 0..k-1
    linkname[q] = link[i].id
    q = q+1
end 
linkname[0]='Date'

CSV.open(file_name, "w") do |csv|
    csv << linkname
    for i in 0..n-1
        csv << results3[i]       
    end
end

puts("Program Finished Successfully!")
