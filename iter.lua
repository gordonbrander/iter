-- # iter.lua
--
-- Transform iterator functions using familiar `map`, `filter`, `reduce`, etc.
-- Transformations are lazy and are only performed item-by-item when the final
-- iterator is consumed.

local exports = {}

-- Capture the state of a stateless iterator and return a stateful iterator
-- of values.
local function iter_values(next, state, i)
  local i, v = i
  return function()
    i, v = next(state, i)
    return v
  end
end
exports.iter_values = iter_values

-- Iterate over the indexed values of a table.
-- Returns a stateful iterator function.
local function ivalues(t)
  return iter_values(ipairs(t))
end
exports.ivalues = ivalues

-- Iterate over the keyed values of a table
local function values(t)
  return iter_values(pairs(t))
end
exports.values = values

-- Create a stateful iterator of `{k, v}` pairs from a table.
local function items(t)
  local v
  local next, state, k = pairs(t)
  return function()
    k, v = next(state, k)
    return {k, v}
  end
end
exports.items = items

-- from the end backwards

local function prev(t, i)
  i = i - 1
  local v = t[i]
  if v then
    return i, v
  end
end
exports.prev = prev

-- Iterate over ipairs in reverse
-- Note this is a STATELESS iterator. Use rev_values if you want to iterate
-- over only values in reverse.
local function rev_ipairs(t)
  return prev, t, #t + 1
end
exports.rev_ipairs = rev_ipairs

local function rev_values(t)
  return iter_values(rev_ipairs(t))
end
exports.rev_values = rev_values

-- Filter a stateful `next` iterator function, returning a new `next` function
-- for the items that pass `predicate` function.
local function filter(predicate, next)
  return function()
    for v in next do
      if predicate(v) then return v end
    end
  end
end
exports.filter = filter

-- Filter a stateful iterator function, removing items that pass the predicate
-- funcition. This function is the compliment of filter.
local function remove(predicate, next)
  return function()
    for v in next do
      if not predicate(v) then return v end
    end
  end
end
exports.remove = remove

-- Map each item with function `a2b`, returning a new iterator of mapped values.
-- Note that because Lua iterators terminate on `nil`, you can stop iteration
-- early by returning `nil` from `a2b`.
local function map(a2b, next)
  return function()
    for v in next do
      return a2b(v)
    end
  end
end
exports.map = map

local function is_nil(x)
  return x ~= nil
end
exports.is_nil = is_nil

-- Map all values with a2b. If mapped value is nil, filter value.
local function filter_map(a2b, next)
  return function()
    for v in next do
      local xv = a2b(v)
      if xv ~= nil then
        return xv
      end
    end
  end
end
exports.filter_map = filter_map

-- Lift a function to become a filter_map iterator transformer.
-- This function serves a similar purpose to Python's list comprehensions
-- and generator expressions. It lets you write your functions for single
-- values, then lift them to deal with any iterator sequence, returning a new
-- iterator sequence. Like Python's list comprehensions, you can both map
-- and filter the values (to filter, simply return `nil`).
local function lift(a2b)
  return function(next)
    return filter_map(a2b, next)
  end
end
exports.lift = lift

local function reductions(step, result, next)
  return function()
    for v in next do
      result = step(result, v)
      return result
    end
  end
end
exports.reductions = reductions

local function take(n, next)
  return function()
    for v in next do
      n = n - 1
      if n > 0 then
        return v
      else
        return nil
      end
    end
  end
end
exports.take = take

local function take_while(predicate, next)
  return function()
    for v in next do
      if predicate(v) then
        return a2b(v)
      else
        return nil
      end
    end
  end
end
exports.map = map

local function skip(n, next)
  return function()
    for v in next do
      n = n - 1
      if n < 1 then return v end
    end
  end
end
exports.skip = skip

local function skip_while(predicate, next)
  local skipping = true
  return function()
    for v in next do
      if skipping then
        skipping = predicate(v)
      else
        return v
      end
    end
  end
end

local function value(x, y)
  if x and y then return y else return x end
end

-- Reduce over an iterator and produce a result.
local function reduce(step, result, next, ...)
  for i, v in next, ... do
    result = step(result, value(i, v))
  end
  return result
end
exports.reduce = reduce

local function append(t, v)
  table.insert(t, v)
  return t
end

-- Insert values from iterator into table `t`.
-- Mutates and returns `t`.
local function extend(t, next, ...)
  return reduce(append, t, next, ...)
end

-- Collect an iterator's values into a table.
local function collect(next, ...)
  return extend({}, next, ...)
end
exports.collect = collect

local function compare_min(x, y)
  if x and x < y then
    return x
  else
    return y
  end
end

-- Get the smallest item in the iterator
local function min(next, ...)
  return reduce(compare_min, nil, next, ...)
end
exports.min = min

local function compare_max(x, y)
  if x and x > y then
    return x
  else
    return y
  end
end

-- Get the largest item in the iterator
local function max(next, ...)
  return reduce(compare_max, nil, next, ...)
end
exports.max = max

-- Partition an iterator into "chunks", returning an iterator of tables
-- containing `chunk_size` items each.
-- Returns a new iterator of chunks
local function partition(chunk_size, next)
  return function()
    local chunk = {}

    for v in next do
      table.insert(chunk, v)
      if #chunk == chunk_size then
        return chunk
      end
    end

    -- If we have any values in the last chunk, return it.
    if #chunk > 0 then
      return chunk
    end

    -- Otherwise, return nothing
  end
end
exports.partition = partition

-- Zip 2 iterators using function f
-- Terminates on shortest iterator.
local function zip_with(f, next_a, next_b)
  return function()
    a = next_a()
    b = next_b()
    if a ~= nil and b ~= nil then
      return f(a, b)
    end
  end
end
exports.zip_with = zip_with

local function table2(a, b)
  return {a, b}
end

-- Zip 2 iterators into an iterator of tables made up of paired values.
local function zip(next_a, next_b)
  return zip_with(table2, next_a, next_b)
end
exports.zip = zip

-- Remove adjacent duplicates from iterator.
local function dedupe(next)
  local prev = dedupe
  return function()
    for curr in next do
      if curr ~= prev then
        prev = curr
        return curr
      end
    end
  end
end
exports.dedupe = dedupe

-- Remove adjacent duplicates from iterator by calculating value with
-- readkey function.
local function dedupe_with(readkey, next)
  local prev = dedupe
  return function()
    for curr in next do
      if readkey(curr) ~= readkey(prev) then
        prev = curr
        return curr
      end
    end
  end
end
exports.dedupe_with = dedupe_with

return exports