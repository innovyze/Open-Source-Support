
markdown
# Folder Structure


## OPEN-SOURCE-SUPPORT
- **01 InfoWorks ICM**
  - **01 Ruby**
    - **01 InfoWorks**
    - **02 SWMM**
      - **0001 - Element and Field Statistics**
        - *(Content omitted for brevity)*
      - **0002 - Tracing Tools**
        - *(Content omitted for brevity)*
      - **0003 - Scenario Tools**
        - *(Content omitted for brevity)*
      - **0004 - Scenario Sensitivity - InfoWorks**
        - *(Content omitted for brevity)*
      - **0005 - Import Export of Data Tables**
        - *(Content omitted for brevity)*
      - **0006 - ICM SWMM vs ICM InfoWorks All Tables**
        - *(Content omitted for brevity)*
      - **0007 - Hydraulic Comparison Tools for ICM InfoWorks and SWMM**
        - *(Content omitted for brevity)*
      - **0008 - Database Field Tools for Elements and Results**
        - *(Content omitted for brevity)*
      - **0009 - Polygon Subcatchment Boundary Tools**
        - *(Content omitted for brevity)*
      - **0010 - List all results fields with Stats**
        - *(Content omitted for brevity)*
      - **0011 - Get results from all timesteps in the IWR File**
        - *(Content omitted for brevity)*
      - **0012 - ICM InfoWorks Results to SWMM5 Summary Tables**
        - *(Content omitted for brevity)*
      - **0013 - SUDS or LID Tools**
        - *(Content omitted for brevity)*
      - **0014 - InfoSewer to ICM Comparison Tools**
        - *(Content omitted for brevity)*
      - **0015 - Export SWMM5 Calibration Files**
        - *(Content omitted for brevity)*
      - **0016 - InfoSWMM and SWMM5 Tools in Ruby**
        - *(Content omitted for brevity)*
      - **0017 - Subcatchment Grid and Tabs Tools**
        - *(Content omitted for brevity)*
      - **0018 - Create Selection list using a SQL query**
        - *(Content omitted for brevity)*
      - **0019 - Node Connection Tools**
        - *(Content omitted for brevity)*
      - **0020 - All Node, Subs and Link IDs Tools**
        - *(Content omitted for brevity)*
      - **0021 - Change the Geometry or Rename IDs**
        - *(Content omitted for brevity)*
      - **0022 - TBA**
        - *(Content omitted for brevity)*
      - **0023 - TBA**
        - *(Content omitted for brevity)*
      - **0024 - Utilities**
        - `asset Id to icm_link_id.md`
        - `asset_id_to_icm_link_id.rb`
        - `Compare ICM trade flow to SWMM Base Flow.rb`
        - `Compare InfoWorks to SWMM for Links.md`
        - `Compare InfoWorks to SWMM for Links.rb`
        - `Compare InfoWorks to SWMM for Nodes.md`
        - `Compare InfoWorks to SWMM for Nodes.rb`
        - `Compare InfoWorks to SWMM for Subcatchment and Node Inflows.md`
        - `Compare InfoWorks to SWMM for Subcatchment and Node Inflows.rb`
        - `dave.rb`
        - `ICM_InfoWorks_Flows_Only.md`
        - `ICM_InfoWorks_Flows_Only.rb`
        - `sonnet_exchange_centroid_bn_cn_network.md`
        - `sonnet_exchange_centroid_bn_cn_networks.rb`

---

### Description

This section focuses on the **0024 - Utilities** directory under the `02 SWMM` folder, which contains various Ruby scripts and documentation files aimed at providing utility functions for comparing and converting between InfoWorks ICM and SWMM data:

- **Asset ID Conversion:**
  - `asset Id to icm_link_id.md` and `asset_id_to_icm_link_id.rb` handle the conversion of asset IDs to ICM link IDs, useful for data integration or comparison.
- **Flow and Trade Comparison:**
  - `Compare ICM trade flow to SWMM Base Flow.rb` compares trade flow data between ICM and SWMM base flow.
- **Link Comparison:**
  - `Compare InfoWorks to SWMM for Links.md` and `Compare InfoWorks to SWMM for Links.rb` provide documentation and script for comparing link data between InfoWorks and SWMM.
- **Node Comparison:**
  - `Compare InfoWorks to SWMM for Nodes.md` and `Compare InfoWorks to SWMM for Nodes.rb` are for comparing node data.
- **Subcatchment and Node Inflows Comparison:**
  - `Compare InfoWorks to SWMM for Subcatchment and Node Inflows.md` and `Compare InfoWorks to SWMM for Subcatchment and Node Inflows.rb` focus on comparing inflows for subcatchments and nodes.
- **General Utility:**
  - `dave.rb` might be a script or utility named after an individual or a specific function, purpose not specified from the name.
- **Flows Only:**
  - `ICM_InfoWorks_Flows_Only.md` and `ICM_InfoWorks_Flows_Only.rb` deal with flow data specifically from ICM InfoWorks, possibly for isolated analysis or comparison.
- **Network Exchange:**
  - `sonnet_exchange_centroid_bn_cn_network.md` and `sonnet_exchange_centroid_bn_cn_networks.rb` might relate to exchanging or analyzing network data,