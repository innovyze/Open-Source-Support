# Common Operations

These pages cover some useful notes and common operations you may need to do in Ruby.

## General

As of version 2024.2, InfoWorks WS Pro and InfoWorks ICM both ship with Ruby 2.4.0. Due to the integration it is not possible to use Ruby Gems (i.e. external libraries from Ruby's package manager) without manually linking the files, but you can use the majority of the Ruby Standard Library. Documentation for the Standard Library (abbreviated stdlib) [can be found here](https://ruby-doc.org/stdlib-2.4.0/).

### Directories (i.e. Paths)

When pointing to a directory or file on your computer, the directory separator can be Unix-style (forward) or Windows-style (backward). i.e.:

- **Unix:** "C:/Badger/Penguin.csv"
- **Windows:** "C:\Badger\Penguin.csv"

Ruby can work with both, but prefers the Unix-style. WS Pro methods can also work with both, but will return Windows-style e.g. from a `#WSApplication.file_dialog` call.

When working with Windows-style paths, remember to escape the backwards slash i.e. `"C:\\Badger\\Penguin.csv"` otherwise Ruby will interpret the backwards slash as a special character (e.g. `\n` is a newline, `\r\n` is a carriage return)

You can switch between them by using `gsub("/","\\")` (for Unix to Windows) or `gsub("\\","/")` (for Windows to Unix). E.g.

```ruby
win_path = "C:\\Badger\\Penguin.csv"
unix_path = win_path.gsub("\\","/")
```

## Network Data

### Links

Links are a common geometry type, so knowing how to work with them can be useful. All links have three required fields: `us_node_id`, `ds_node_id`, and `suffix`. The `OID` or `ID` of a link is the combination of all three separated by periods (i.e. `us.ds.suffix`).

If you create a new link and set an upstream and downstream node, the geometry is handled automatically (in fact, the update is linked to setting the upstream and downstream nodes). If you need to work directly with the geometry of a link then this data is stored in the `bends` field, which is not visible in the user interface. The `bends` field is an array containing the position of each vertex (point) along the line, in a sequence of X,Y,X,Y numbers. A simple link between two points would have a minimum of 4 entries in this array, representing the start and end vertices.

#### Simplify Link Geometry

To simplify the geometry of a link:

```ruby
network.row_objects_selection("_links").each do |link|
  link["bends"] = [link.us_node["X"], link.us_node["Y"], link.ds_node["X"], link.ds_node["Y"]]
  link.write
end
```

#### Reverse Link

To reverse a link:

```ruby
network.row_objects_selection("_links").each do |link|
  old_bends = link["bends"]
  new_bends = Array.new
  while !old_bends.empty?
    new_bends.concat(old_bends.pop(2))
  end

  old_us_id = link["us_node_id"]
  link["us_node_id"] = link["ds_node_id"]
  link["ds_node_id"] = old_us_id
  link["bends"] = new_bends

  link.write
end
```

### Structured Data

Structured data, also referred to as Structs or Blobs, are the tables within an object e.g. node demand by category, or a fixed head profile. They behave like an array, except they have a fixed size so we cannot dynamically add to them without first changing that size.

For these examples, assume that we have a reservoir object, and we want to work with the Depth Volume curve.

```ruby
network = WSApplication.current_network
res = network.row_object('wn_reservoir', 'MyRes')
```

We want to check what the first volume is. We could save the structure to a variable, then the first row (index 0), and access the field 'volume':

```ruby
depth_struct = res.depth_volume
depth_struct_row = depth_struct[0]
puts depth_struct_row['volume']
```

Or we could write this as one line:

```ruby
puts res.depth_volume[0]['volume']
```

We can write data to structs, though we have to be sure that the index exists e.g. by using `#size = 1`

```ruby
depth_struct = res.depth_volume
depth_struct[0]['volume'] = 100
depth_struct.write
```

If we have an array of values we want to put into the depth volume, we first have to make sure the size of the struct matches our array, and then iterate the array, placing the values at the appropriate indexes:

```ruby
values = [
  [1, 100],
  [5, 1000]
]

depth_struct = res.depth_volume
depth_struct.size = values.size

values.each_with_index do |(depth, volume), i| # (depth, volume) is splitting each array within values
  depth_struct[i]['depth'] = depth
  depth_struct[i]['volume'] = volume
end

depth_struct.write
```


