# GMR Test Case Scripts

These scripts demonstrate how to create test cases for GMR. They can be run from the user interface.

Currently there is no way to directly load test cases into a GMR table, so each script exports to CSV and this has to be imported into a GMR configuration.

- [valve_shut_order.rb](./valve_shut_order.rb) Creates a test for every potential order of valve closures, note that this can quickly get out of hand i.e. for 7 valves it's 7! (factorial) or 5040 cases
