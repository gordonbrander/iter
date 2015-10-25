# iter

Map, filter and transform lazy iterators.

iter offers the familiar `map()`, `filter()`, etc but with a twist: rather than transforming tables, iter transforms the values in iterators. Transformations are lazy and no work is done until iterator is consumed (usually with a `for` loop).

## Example

    -- Import iter functions
    local iter = require('iter')
    local map = iter.map
    local filter = iter.filter
    local values = iter.values

    -- Import an enormous table
    local large_table = require('largetable.lua')

    -- Create an iterator function for table values
    local v = values(very_large_table)

    -- Filter and transform values. At each step, a new iterator function is
    -- returned for the transformed values. No intermediate tables are created.
    local odd_values = filter(is_odd, v)
    local values_greater_than_2 = filter(is_greater_than_2, odd_values)
    local square_roots = map(square_root, values_greater_than_2)

    -- Consume our final iterator. This is when all the work happens.
    for v in square_roots do
      print(v)
    end


## Installation

Using [Luarocks](https://luarocks.org):

    luarocks install iter

Then in your Lua file, you can:

    local iter = require('iter')

That's it!