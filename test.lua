local iter = require("iter")

local ten = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

local MSG_TEMPLATE = [[Test failed:
%s
Expected: %s
Got: %s]]

local function test(x, y, msg)
  assert(x == y, string.format(MSG_TEMPLATE, msg or "", y, x))
  print(msg)
end

do
  local values = iter.values(ten)
  assert(values() == 1, "values iterates over values")
end

do
  local values = iter.values(ten)
  local odd = iter.filter(function (x)
    return x % 2 == 1
  end, values)
  test(odd(), 1, "filter() filters false values")
  test(odd(), 3, "filter() filters false values")
end

do
  local values = iter.values(ten)
  local odd = iter.remove(function (x)
    return x % 2 == 1
  end, values)
  test(odd(), 2, "remove() rejects true values")
  test(odd(), 4, "remove() rejects true values")
end

do
  local x = iter.values(ten)
  x = iter.filter_map(function (y)
    if y % 2 > 0 then
      return "mapped_" .. y
    end
  end, x)
  local t = iter.collect(x)
  test(t[1], "mapped_1", "filter_map maps values")
  test(#t, 5, "filter_map filters out nil values")
end

do
  local x = iter.values(ten)
  local function update_odd(y)
    if y % 2 > 0 then
      return "Testing" .. y
    end
  end
  local map_filter_odd = iter.lift(update_odd)
  x = map_filter_odd(x)
  local t = iter.collect(x)
  test(type(map_filter_odd), 'function', 'lift() lifts a function into an iter function')
  test(#t, 5, "lifted function filter_maps values")
end

do
  local x = iter.values(ten)
  local y = iter.take(3, x)
  local t = iter.collect(y)
  test(#t, 3, "take() takes correct number of values")
end

do
  local x = iter.values(ten)
  local y = iter.skip(3, x)
  local t = iter.collect(y)
  test(#t, 7, "skip() skips corrrect number of values")
end

do
  local x = iter.values(ten)
  local y = {}
  iter.extend(y, x)
  test(#y, 10, "extend() appends indexed values to table, mutating it")
end

do
  local min = iter.min(iter.values(ten))
  local nil_min = iter.min(iter.values({}))
  test(min, 1, "min() finds the lowest value in the iterator")
  test(nil_min, nil, "min() returns nil if iterator is empty")
end

do
  local max = iter.max(iter.values(ten))
  local nil_max = iter.max(iter.values({}))
  test(max, 10, "max() finds the highest value in the iterator")
  test(nil_max, nil, "max() returns nil if iterator is empty")
end

do
  local function sum(x, y) return x + y end
  local rx = iter.reductions(sum, 0, iter.values(ten))
  local tx = iter.collect(rx)
  test(#tx, 10, "reductions() does correct number of steps")
  test(tx[2], 3, "reductions() iterates through each step of reduction")
end