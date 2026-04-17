## Export Dashboards from the Database after updating

#Select the WGDatabaswe
db = WSApplication.open('//localhost:40000/database',false)
#Define the Dashboard's location in the database
mo=db.model_object'>MASG~MasterGroup>AG~AssetGroup>DASH~Dashboard'
#Update said Dashboard with current network values
mo.update_dashboard
#Export said Dashboard to location, format must be html
mo.export 'c:\temp\Dashboard\badger.html','html'