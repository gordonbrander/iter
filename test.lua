local iter = require("iter")

local ten = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

local MSG_TEMPLATE = [[Test failed:
%s
Expected: %s
Got: %s]]

local function expect(x, y, msg)
  assert(x == y, string.format(MSG_TEMPLATE, msg or "", y or "", x or ""))
  print(msg)
end

do
  local values = iter.values(ten)
  expect(values(), 1, "values iterates over values")
end

do
  local values = iter.values(ten)
  local odd = iter.filter(function (x)
    return x % 2 == 1
  end, values)
  expect(odd(), 1, "filter(f, iter) filters false values")
  expect(odd(), 3, "filter(f, iter) filters false values")
end

do
  local values = iter.values(ten)
  local odd = iter.remove(function (x)
    return x % 2 == 1
  end, values)
  expect(odd(), 2, "remove(f, iter) rejects true values")
  expect(odd(), 4, "remove(f, iter) rejects true values")
end

do
  local x = iter.values(ten)
  x = iter.map(function (y)
    if y % 2 > 0 then
      return "mapped_" .. y
    end
  end, x)
  local t = iter.collect(x)
  expect(t[1], "mapped_1", "map(f, iter) maps values")
  expect(#t, 5, "map(f, iter) filters out nil values")
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
  expect(type(map_filter_odd), 'function', 'lift(f) lifts a function into an iter function')
  expect(#t, 5, "lifted function filter_maps values")
end

do
  local x = iter.values(ten)
  local y = iter.take(3, x)
  local t = iter.collect(y)
  expect(#t, 3, "take(n, iter) takes correct number of values")
end

do
  local x = iter.values(ten)
  local y = iter.take_while(function(x) return x < 4 end, x)
  local t = iter.collect(y)
  expect(#t, 3, "take_while(f, iter) takes correct number of values")
end

do
  local x = iter.values(ten)
  local y = iter.skip(3, x)
  local t = iter.collect(y)
  expect(#t, 7, "skip(n, iter) skips corrrect number of values")
end

do
  local x = iter.values(ten)
  local y = iter.skip_while(function(x) return x < 4 end, x)
  local t = iter.collect(y)
  expect(#t, 6, "skip_while(f, iter) skips correct number of values")
end

do
  local x = iter.values(ten)
  local y = {}
  iter.extend(y, x)
  expect(#y, 10, "extend(t, iter) appends indexed values to table, mutating it")
end

do
  local min = iter.min(iter.values(ten))
  local nil_min = iter.min(iter.values({}))
  expect(min, 1, "min(iter) finds the lowest value in the iterator")
  expect(nil_min, nil, "min(iter) returns nil if iterator is empty")
end

do
  local max = iter.max(iter.values(ten))
  local nil_max = iter.max(iter.values({}))
  expect(max, 10, "max(iter) finds the highest value in the iterator")
  expect(nil_max, nil, "max(iter) returns nil if iterator is empty")
end

do
  local function sum(x, y) return x + y end
  local rx = iter.reductions(sum, 0, iter.values(ten))
  local tx = iter.collect(rx)
  expect(#tx, 10, "reductions(step, x, iter) does correct number of steps")
  expect(tx[2], 3, "reductions(step, x, iter) iterates through each step of reduction")
end

do
  expect(iter.prev(ten, #ten + 1), 10, "prev(t, i) steps over values in reverse")
end

do
  local rev = iter.rev_ivalues(ten)
  local t = iter.collect(rev)
  expect(t[1], 10, "rev_ivalues(t) iterates over values in reverse")
end

do
  local x = iter.ivalues(ten)
  local y = iter.rev_ivalues(ten)
  local zipped = iter.zip(x, y)
  local t = iter.collect(zipped)
  expect(type(t[1]), 'table', "zip(a, b) creates an iterator of tables")
  expect(t[1][1], 1, "zip(a, b) puts a[n] on the left of each pair")
  expect(t[1][2], 10, "zip(a, b) puts b[n] on the right of each pair")
end

do
  local x = iter.ivalues({1, 2, 3, 4, 5})
  local n = iter.sum(0, x)
  expect(n, 15, "num(n, iter) sums all the number values in the iterator with `n`")
end

do
  local x = iter.ivalues({1, 2, 3, 4, 5})
  local n = iter.find(function (x) return x == 3 end, x)
  expect(n, 3, "find(f, iter) finds the first match")

  local y = iter.ivalues({1, 2, 3, 4, 5})
  local o = iter.find(function (x) return x == 10 end, x)
  expect(o, nil, "find(f, iter) returns nil when nothing passes")
end

do
  local x = iter.ivalues(ten)
  local chunks = iter.partition(3, x)
  local y = iter.collect(chunks)
  expect(#y, 4, "partition(n, iter) creates correct number of chunks")
  expect(#y[1], 3, "partition(n, iter) creates correct chunk sizes")
  expect(#y[4], 1, "partition(n, iter) appends leftovers to last chunk")
end

do
  local x = iter.ivalues({1, 2, 2, 2, 3, 3, 4, 4, 4, 4, 4, 3, 3})
  local chunks = iter.dedupe(x)
  local y = iter.collect(chunks)
  expect(#y, 5, "dedupe(iter) compacts iter to adjacent unique")
  expect(y[3], 3, "dedupe(iter) dedupes correctly")
  expect(y[4], 4, "dedupe(iter) dedupes correctly")
  expect(y[5], 3, "dedupe(iter) only dedupes adjacent")
end
