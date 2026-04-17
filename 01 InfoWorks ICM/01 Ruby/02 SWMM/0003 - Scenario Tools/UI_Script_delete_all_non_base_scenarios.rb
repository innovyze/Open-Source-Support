net=WSApplication.current_network
net.scenarios do |s|
    if s != 'Base'
        net.delete_scenario(s)
    end
end
puts 'All scenarios deleted'