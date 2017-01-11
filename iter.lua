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
-- Returns a stateful iterator function that returns one values.
local function ivalues(t)
  return iter_values(ipairs(t))
end
exports.ivalues = ivalues

-- Iterate over the keyed values of a table.
-- Returns a stateful iterator function that returns one value.
local function values(t)
  return iter_values(pairs(t))
end
exports.values = values

-- Create a stateful iterator of `{k, v}` pairs from a table.
-- Returns a stateful iterator function.
local function items(t)
  local v
  local next, state, k = pairs(t)
  return function()
    k, v = next(state, k)
    return {k, v}
  end
end
exports.items = items

-- Like `next()`, but works from right-to-left.
local function prev(t, i)
  if i then
    i = i - 1
    local v = t[i]
    if v then
      return i, v
    end
  end
end
exports.prev = prev

-- Iterate over ipairs in reverse.
-- Note this is a STATELESS iterator. Use `rev_values` if you want to iterate
-- over only values in reverse.
--
--     for i, v in rev_ipairs(t) do
--       print(v)
--     end
local function rev_ipairs(t)
  return prev, t, (#t + 1)
end
exports.rev_ipairs = rev_ipairs

-- A stateful iterator for reversed indexed values of table.
-- Returns a stateful iterator function.
local function rev_ivalues(t)
  return iter_values(rev_ipairs(t))
end
exports.rev_ivalues = rev_ivalues

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
-- function. This function is the compliment of filter.
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
-- This function serves a similar purpose to Python's list comprehensions
-- and generator expressions. It lets you write your functions for single
-- values, then have them deal with any iterator sequence, returning a new
-- iterator sequence. Like Python's list comprehensions, you can both map
-- and filter the values (to filter, simply return `nil`).
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
local function lift(a2b)
  return function(next)
    return filter_map(a2b, next)
  end
end
exports.lift = lift

-- Step through iterator with a reducing function and a starting `result value`.
-- Returns an iterator for the result at each step of the reduction.
--
-- Example:
--
--     local v = values({1, 2, 3, 4})
--     local function sum(x, y) return x + y end
--     local r = reductions(sum, 0, v)
--     print(collect(r))
--     --- {1, 3, 6, 10}
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
      if n >= 0 then
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
      if n < 0 then
        return v
      end
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

-- Reduce over an iterator and produce a result.
local function reduce(step, result, next)
  for v in next do
    result = step(result, v)
    if result == nil then
      break
    end
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
exports.extend = extend

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

local function find(f, next, ...)

end

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

-- Zip 2 iterators using function `f`.
-- Each step, takes one item from the left and on item from the right iterator,
-- and passes these items to function `f`. The return value of `f` becomes the
-- value at that step of the returned iterator.
-- Terminates on shortest iterator.
--
-- Example:
--
--     zip_with(table2, iter_1, iter_2)
--     -- <{1, 2}, {3, 4}, {5, 6}, ...>
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

-- Pack 2 arguments into a table.
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