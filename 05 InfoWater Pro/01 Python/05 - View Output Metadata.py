from infowater.output.manager import Manager as OutMan
import json

out_path = "C:/InfoWater Pro Examples/SAMPLE.OUT/SCENARIO/BASE/HYDQUA.OUT"
outman = OutMan(out_path)

metadata = outman.get_metadata() 
print(json.dumps(vars(metadata), indent=4))
