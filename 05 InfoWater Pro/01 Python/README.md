# InfoWater Pro open source scripts
This repository will host open source code that can be used in InfoWater Pro 2025.0 or greater.


## Sample getting started
To get started reading InfoWater Pro results, you will need to import the Manager class and call it on an output file path to instantiate an output object for scripting. 

Below is a simple example to import the class and call it on an output file. The example creates a new output manager object called “outman” for the specified model output data with all of the behaviors inherited from the class. The script can then call any of the available methods to extract results.

```python
from infowater.output.manager import Manager
outman = Manager("C:\\Users\\Public\\Documents\\InfoWater Pro\\Examples\\Net1.OUT\\SCENARIO\\BASE\\HYDQUA.OUT")
outman.get_range_data("Junction","Pressure","Avg")
```

## Copy examples to your project
You can download any of the included .ipynb files and add them to your ArcGIS Pro catalog by going to Notebooks and selecting Add Notebook.
Be sure to modify inputs like project paths as needed.
