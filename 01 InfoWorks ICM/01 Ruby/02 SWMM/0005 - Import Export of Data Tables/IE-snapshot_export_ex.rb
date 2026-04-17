begin

db = WSApplication.open('localhost:40000/IA_NEW',false)
nw = db.model_object_from_type_and_id('Collection Network', 1246)
nw.update
on = nw.open

exp=Hash.new
exp['SelectedOnly'] = false
exp['IncludeImageFiles'] = 	false
exp['IncludeGeoPlanPropertiesAndThemes'] = 	false
#exp['ChangesFromVersion'] = nil
#exp['Tables'] = ["cams_cctv_survey"]

on.snapshot_export_ex('export.isfc',exp)

end