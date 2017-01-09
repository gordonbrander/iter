local iter = require("iter")

local ten = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

local MSG_TEMPLATE = [[Test failed:
%s
Expected: %s
Got: %s]]

local function test(x, y, msg)
  assert(x == y, string.format(MSG_TEMPLATE, msg or "", x, y))
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
      return "Testing" .. y
    end
  end, x)
  local t = iter.collect(x)
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