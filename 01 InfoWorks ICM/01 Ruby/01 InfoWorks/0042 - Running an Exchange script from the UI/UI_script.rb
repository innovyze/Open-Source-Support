$version = "2021.7"
$exchange_path = "C:/Program Files/Innovyze Workgroup Client #{$version}/IExchange.exe"

$param1 = "This is a string"
$param2 = WSApplication.current_network.model_object.name
$script_path = "C:/Users/daniel.moreira/Innovyze, INC/Innovyze Support - Products/InfoWorks ICM/03 Scripts/01 Ruby/0000 - Testing environment/02 Exchange/EX_script.rb"

system("\"#{$exchange_path}\" \"#{$script_path}\" ICM \"#{$param1}\" \"#{$param2}\" & pause")