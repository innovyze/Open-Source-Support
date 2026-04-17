# SWMM Subcatchment Export Script Documentation

## Overview
This Ruby script automates the export of SWMM subcatchment data from InfoWorks ICM/InfoSWMM to CSV format. It provides comprehensive field selection for watershed modeling parameters, statistical analysis capabilities, and user-friendly prompts for customizing subcatchment data exports.

## Key Features

### **Data Export Capabilities**
- Exports selected SWMM subcatchment objects to timestamped CSV files
- Supports 80+ configurable subcatchment parameters
- Handles complex data types (arrays, land use coverages, pollutant loadings)
- User-selectable field configuration with individual toggles

### **Statistical Analysis**
- Optional statistical calculations for numeric fields
- Generates formatted tables showing:
  - Count, Min, Max, Mean, Standard Deviation
  - Automatically excludes non-numeric fields (IDs, patterns, arrays)
- Uses sample standard deviation formula (n-1 denominator)

### **User Interface**
- Interactive prompts for field selection
- "Select/Deselect All" toggle option
- Export folder selection with validation
- Summary dialog upon completion
- Progress tracking and comprehensive error reporting

## Supported SWMM Subcatchment Fields

### **Core Properties (Default: Enabled)**
- **Subcatchment ID**: Unique identifier
- **Raingauge ID**: Associated precipitation gauge
- **Outlet ID**: Discharge destination (node or subcatchment)
- **Area**: Total subcatchment area
- **Width**: Characteristic width for flow routing
- **Slope**: Average surface slope (%)
- **Percent Impervious**: Impervious area percentage

### **Runoff Parameters**
- **Roughness Coefficients**: Manning's N for impervious and pervious surfaces
- **Storage Depths**: Depression storage for impervious and pervious areas
- **Percent Zero Storage**: Areas with no depression storage
- **Routing Options**: Flow routing to outlet or pervious areas
- **Percent Routed**: Fraction of runoff routed to specific destination

### **Infiltration Models**
#### **Horton Infiltration**
- Maximum infiltration rate
- Minimum infiltration rate  
- Decay constant
- Drying time
- Maximum infiltration volume (Modified Horton)

#### **Green-Ampt Infiltration**
- Suction head
- Saturated hydraulic conductivity
- Initial moisture deficit

#### **SCS Curve Number**
- Curve number
- Initial abstraction depth
- Initial abstraction factor
- Initial abstraction type

### **Groundwater Parameters**
- **Aquifer Properties**: ID, node connections, elevations
- **Initial Conditions**: Groundwater elevation, moisture content
- **Flow Coefficients**: Groundwater flow equations and parameters
- **Lateral/Deep Flow**: Groundwater interaction equations
- **Surface Groundwater**: Upper zone coefficients and depths

### **Complex Data Arrays**
#### **Land Use Coverages**
- Land use type and area assignments
- Serialized as `LandUse:Area` pairs

#### **Pollutant Loadings**
- Pollutant type and buildup rates
- Serialized as `Pollutant:BuildUp` pairs

#### **Soil Composition**
- Soil type and area distributions
- Serialized as `SoilID:Area` pairs

#### **SUDS Controls**
- Sustainable Urban Drainage Systems
- Control ID, structure type, and area
- Serialized as `ID:Structure:Area` format

#### **Boundary Geometry**
- Subcatchment boundary coordinates
- Vertex arrays as X,Y coordinate pairs

### **Advanced Parameters**
- **Snow Pack ID**: Winter runoff modeling
- **Time Patterns**: Temporal variation patterns for parameters
- **Hydraulic Length**: Flow path characteristics
- **Curb Length**: Street infrastructure
- **Time of Concentration**: Runoff timing parameters
- **Shape Factor**: Nonlinear reservoir routing

### **User-Defined Fields**
- **10 User Number Fields**: Custom numeric parameters
- **10 User Text Fields**: Custom text annotations
- **Notes**: Detailed descriptions
- **Hyperlinks**: External references and documentation

## Technical Implementation

### **SWMM-Specific Features**
- Targets `sw_subcatchment` objects specifically
- Compatible with SWMM5 watershed modeling structure
- Handles multiple infiltration model parameters
- Processes complex land use and pollutant data structures

### **Data Processing**
- Processes only selected subcatchment objects
- Handles complex array serialization with custom delimiters
- Sanitizes CSV data (removes problematic characters)
- Flexible ID field detection (subcatchment_id or id)

### **Array Data Serialization**
- **Coverages**: `LandUse1:Area1;LandUse2:Area2`
- **Loadings**: `Pollutant1:BuildUp1;Pollutant2:BuildUp2`
- **SUDS Controls**: `ID1:Structure1:Area1||ID2:Structure2:Area2`
- **Boundaries**: `X1,Y1;X2,Y2;X3,Y3`

### **Error Handling**
- Network validation and connection checks
- Subcatchment object existence verification
- File permission and disk space validation
- Graceful handling of missing attributes
- Comprehensive logging with subcatchment IDs

### **Performance Features**
- Iterator-based processing for memory efficiency
- Progress tracking with object counts
- Execution timing reports
- Automatic cleanup of empty files

## Usage Instructions

### **Prerequisites**
- InfoSWMM or InfoWorks ICM environment
- Network with SWMM subcatchment objects loaded
- Write permissions to export directory

### **Execution Steps**
1. **Select Subcatchments**: Use the GUI to select subcatchment objects for export
2. **Run Script**: Execute within the application environment
3. **Configure Export**:
   - Choose export folder
   - Select desired fields (core fields enabled by default)
   - Enable statistics calculation if needed
4. **Review Results**: Check console output and summary dialog

### **Output Files**
- CSV format: `selected_swmm_subcatchments_export_YYYYMMDD_HHMMSS.csv`
- Automatic cleanup of empty files
- Timestamped for version control

## Statistical Output Example

```
| Parameter (Header)                | Count  | Min      | Max      | Mean         | Std Dev      |
|-----------------------------------|--------|----------|----------|--------------|--------------|
| Area                              | 125    | 0.500    | 45.800   | 12.350       | 8.450        |
| Width                             | 125    | 25.000   | 500.000  | 185.200      | 125.600      |
| Slope_pct                         | 125    | 0.500    | 8.500    | 2.150        | 1.750        |
| PctImperv                         | 125    | 15.000   | 95.000   | 65.500       | 22.300       |
| N_Imperv                          | 125    | 0.010    | 0.020    | 0.013        | 0.003        |
| N_Perv                            | 125    | 0.100    | 0.400    | 0.180        | 0.085        |
```

## SWMM Integration Notes

### **Watershed Modeling Compatibility**
- **Runoff Generation**: Complete surface runoff parameter set
- **Infiltration Models**: Support for all SWMM infiltration methods
- **Groundwater**: Comprehensive aquifer interaction parameters
- **Land Use**: Detailed coverage and pollutant loading capabilities

### **Model Setup Support**
- **Precipitation**: Raingauge assignments for meteorological input
- **Routing**: Flow routing options and outlet connections
- **Time Patterns**: Temporal variation support for dynamic parameters
- **Quality Modeling**: Pollutant buildup and washoff parameters

### **Field Verification**
- Field symbols must match actual SWMM API method names
- Debugging block available for method inspection
- SWMM version-specific field availability may vary

### **Statistics Exclusions**
- Text fields (IDs, notes, pattern names)
- Complex arrays (coverages, loadings, boundaries)
- Model type fields (infiltration, runoff models)
- Equation references and pattern IDs

## Error Messages and Troubleshooting

### **Common Issues**
- **"No network loaded"**: Ensure a SWMM network is open before running
- **"No 'sw_subcatchment' objects found"**: Verify subcatchments exist in the model
- **"Permission denied"**: Check folder write permissions
- **"AttributeMissing"**: Field not available in current SWMM API version
- **"No subcatchments selected"**: Select subcatchment objects in GUI before export

### **Debug Mode**
Uncomment the debugging block to inspect available methods:
```ruby
# subcatchment_example = cn.row_objects('sw_subcatchment').first 
# puts subcatchment_example.methods.sort.inspect
```

## Configuration Notes

### **Field Selection Strategy**
- Core watershed parameters enabled by default
- Advanced groundwater and infiltration fields disabled by default
- Complex array fields require careful interpretation
- User fields available for custom model extensions

### **Infiltration Model Considerations**
- Different infiltration models use different parameter sets
- Only relevant parameters will have values for each subcatchment
- Model type field indicates which parameters are active

### **Land Use and Pollutant Data**
- Complex arrays serialized with custom delimiters
- May require post-processing for detailed analysis
- Useful for model validation and parameter comparison

## Integration with SWMM Workflow

### **Model Development Applications**
- Parameter validation across subcatchments
- Watershed characterization analysis
- Model calibration support through statistical analysis
- Quality assurance for large watershed models

### **Comparative Analysis**
- Compare subcatchment parameters between scenarios
- Validate design assumptions across watershed areas
- Export for external watershed analysis tools
- Generate reports for environmental impact studies

### **Data Management**
- Bulk parameter review and validation
- Model documentation and archiving
- Integration with GIS and other modeling tools
- Support for peer review and quality control

This script forms part of the larger InfoWorks automation suite, specifically designed for comprehensive SWMM watershed analysis and comparison tasks as outlined in Edition 41-44 of the series, enabling detailed subcatchment parameter analysis for urban stormwater modeling.