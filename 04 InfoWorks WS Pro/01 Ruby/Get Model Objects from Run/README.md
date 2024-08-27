# Get Model Objects From Run

This script demonstrates how to access the model objects (with commit ids) from a run. It is intended to run from Exchange and will perform a debug print like this:

```txt
network: BridgeNet (1517)
network_commit_id: 9
control: BridgeCon (1518)
control_commit_id: 6
ldc:
ldc_commit_id:
ddg: BridgeTown ADAW (1520)
```

You can use the method `get_model_objects_from_run` in your own scripts.
