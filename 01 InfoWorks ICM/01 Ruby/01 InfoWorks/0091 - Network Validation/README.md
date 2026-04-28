# Network Validation

Validates an InfoWorks ICM Model Network for a specified scenario and prints all
validation messages (errors, warnings, and informational notices) to the console.

## Background

When a network is committed without being validated, simulations will fail with:

> "The network was not validated before committing so may not be used in a simulation."

This script runs the same validation check that ICM performs interactively, allowing
you to review messages before committing or running a simulation.

## Configuration

Edit the configuration section at the top of `EX_script.rb`:

```ruby
NETWORK_ID    = 123     # Required: Integer ID of the Model Network
DATABASE_PATH = nil     # nil = last opened database, or explicit path
SCENARIO      = 'Base'  # Scenario name to validate
```

To find a network's ID, right-click the network in the ICM tree and select
**Properties**, or hover over it to see the ID in the status bar.

## Output

```
============================================================
Network Validation
============================================================
Database : snumbat://localhost:40000/My Database
Network  : Sewer Network (ID: 123)
Scenario : Base

Errors   : 0
Warnings : 0
Total    : 2

------------------------------------------------------------
This manhole (and possibly others) has shaft area below minimum in Simulation Parameters
This manhole (and possibly others) has chamber area below minimum in Simulation Parameters
------------------------------------------------------------
```

## Notes

- `error_count` and `warning_count` do not include informational messages — always
  check `length` for the true total number of messages.