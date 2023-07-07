# Source https://gist.github.com/sancarn/00e44231eba3ac20123e10601f236175

require_relative('Powershell.rb')
require 'json'

net = WSApplication.current_network
data = {}
data["head"] =["Table name", "Object ID"]
data["body"] = []
selectedItems = []

#Get all selected items
net.table_names.each do |table|
	selection = net.row_object_collection_selection(table)
	selection.each do |o|
		data["body"].push([table,o.id])
		selectedItems.push(o)
	end
end

#Build GUI
gui=<<END_GUI
#Get data from ruby as JSON string
$data = #{data.to_json.to_json.gsub(/\\"/,"\"\"")}
$data = ConvertFrom-Json $data


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#region begin GUI{

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '500,400'
$Form.text                       = "Form"
$Form.TopMost                    = $false
$form.Resize                     = $false
$form.FormBorderStyle            = 'FixedToolWindow'

$okButton                        = New-Object System.Windows.Forms.Button
$okButton.text                   = "OK"
$okButton.width                  = 150
$okButton.height                 = 50
$okButton.location               = New-Object System.Drawing.Point(96,330)
$okButton.Add_Click({
    ForEach($item in $ListView1.SelectedIndices){
        Write-Host $item
    }
    $Form.close()
})

$cancelButton                    = New-Object System.Windows.Forms.Button
$cancelButton.text               = "Cancel"
$cancelButton.width              = 150
$cancelButton.height             = 50
$cancelButton.location           = New-Object System.Drawing.Point(256,330)
$cancelButton.add_click({
	Write-Host "Cancel"
    $Form.close()
})

$ListView1                       = New-Object System.Windows.Forms.ListView
$ListView1.text                  = "listView"
$ListView1.width                 = 490
$ListView1.height                = 300
$ListView1.location              = New-Object System.Drawing.Point(5,5)
$ListView1.MultiSelect = 1
$ListView1.View = 'Details'
$ListView1.FullRowSelect = 1
$ListView1.Font = 'Microsoft Sans Serif,20'

#Generate headers
ForEach($d in $data.head){
    $col = $ListView1.columns.add($d)
    $col.width = -2
}

#Generate items
ForEach($item in $data.body){
    $lvi = New-Object System.Windows.Forms.ListViewItem($item)
    For($i=1;$i -lt $item.length; $i++){
        [void]$lvi.SubItems.Add($item[$i])
    }
   [void]$ListView1.items.add($lvi)
}

$Form.controls.AddRange(@($okButton, $cancelButton ,$ListView1))

[void]$Form.ShowDialog()
END_GUI

#Execute Powershell script, display GUI and retrieve user selection.
guiData = Powershell.exec(gui)

#If cancel button was not clicked then...
if guiData[:STDOUT] != "Cancel\n"
	#Get refined selection from STDOUT
	refinedSelection = guiData[:STDOUT].split("\n").map {|i| i.to_i}

	#If object NOT within selected range, unselect it.
	selectedItems.each_with_index do |o,ind|
		if !(refinedSelection.include? ind)
			o.selected = false;
		end
	end
end