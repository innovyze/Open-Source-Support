# Modify Control and Run

This script demonstrates how you can automate basic model updates that also trigger a new simulation. It is a basic example, but demonstrates a flexible approach to this task.

The script works by taking the path to a JSON file as an input, which would look like this:

```json
{
  "database": null,
  "run_id": 3171,
  "run_time": "2024/01/01 00:00",
  "updates": [
    { "id": "290848", "table": "wn_valve", "fields": { "mode": "THV", "opening": 0 } },
    { "id": "290874", "table": "wn_valve", "fields": { "mode": "THV", "opening": 0 } }
  ],
  "flag": "upd",
  "message": "Update"
}
```

Where the 'updates' array contains a list of objects to update, identified by their Asset ID. This can then update fields on that object's control properties.

This could be expanded in various ways:

- Split 'fields' into 'network_fields' and 'control_fields', and allow updates to both
- Support updating structured objects like node demand, valve profiles, pump schedules
- Return results
- Compare before/after results (would need to guarantee that a new run is saved, currently experimental runs are updated in place which removes the old results)
