local iter = require("iter")

local ten = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

do
  local values = iter.values(ten)
  assert(values() == 1, "values iterates over values")
end

do
  local x = iter.values(ten)
  x = iter.filter_map(function (y)
    if y % 2 > 0 then
      return "Testing" .. y
    end
  end, x)
  local t = iter.collect(x)
  assert(#t == 5)
end

do
  local x = iter.values(ten)
  local y = iter.take(3, x)
  local t = iter.collect(y)
  assert(#t == 3, "take 3")
end

do
  local x = iter.values(ten)
  local y = iter.skip(3, x)
  local t = iter.collect(y)
  assert(#t == 7,  "skip 3")
end