# Demand Diagram Proxy

This script acts as a proxy for WS Pro demand diagrams, allowing them to be edited more easily from Ruby scripts. These methods only work with Exchange.

Because Demand Diagrams are not network objects in the Ruby API, it is not possible to directly edit their contents. In recent versions of the software, JSON import and export support was added which makes it possible to export the data to a standard format, edit it, and then import a new demand diagram. This Ruby script simplifies this process, and presents a 'proxy' class for the demand diagram which can be modified and then re-imported.

To use the script, you will need to `require` it - see the example.

## Notes

### Time Values

Demand Diagrams in WS Pro store values relative to week days, therefore it would not be strictly accurate to convert values to a Ruby `DateTime` or `Time` object which are absolute/ Therefore the time values in each profile are stored as seconds from the first day of the week (in WS Pro, this is Monday), i.e.:

- Monday 00:15 is 900 seconds
- Tuesday 01:30 is 91800 seconds

This makes it compatible with Ruby's `Time` class, i.e.

```ruby
require 'time'

base = Time.new(2001, 1, 1)
puts base.strftime("%F %T")
# => 2001-01-01 00:00:00

base += 900
puts base.strftime("%F %T")
# => 2001-01-01 00:15:00
```

### Validation

Currently, no validation is performed when updating values or re-importing the demand diagram.
