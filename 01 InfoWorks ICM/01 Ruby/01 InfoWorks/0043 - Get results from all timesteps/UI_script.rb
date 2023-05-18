require 'date'
net=WSApplication.current_network
ts_size=net.list_timesteps.count
ts_g_size=net.list_gauge_timesteps.count
ts=net.list_timesteps
ts_g=net.list_gauge_timesteps
res_field_name='depnod'
net.each_selected do |sel|
    ro=net.row_object('hw_node',sel.node_id)
    rs_size=ro.results(res_field_name).count
    rs_g_size=ro.gauge_results(res_field_name).count
    if rs_g_size==ts_g_size
        puts "Gauge Results: #{sel.node_id}"
        i=0
        ro.gauge_results(res_field_name).each do |result|
            puts "#{ts_g[i]}: #{result}"
            i+=1
        end
    elsif rs_size==ts_size
        puts "Results: #{sel.node_id}"
        j=0
        ro.results(res_field_name).each do |result|
            puts "#{ts[j]}: #{result}"
            j+=1
        end
    end
    puts ""
end