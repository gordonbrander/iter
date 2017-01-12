-- # iter.lua
--
-- Map, filter and transform lazy iterators.
--
-- iter offers the familiar `map()`, `filter()`, etc but with a twist: rather than transforming tables, iter transforms the iterator. Transformations are lazy and no work is done until iterator is consumed (usually with a `for` loop). This is faster and more memory efficient, since items are transformed one-by-one as iterator is consumed and no interim tables are created.
--
-- Transform iterator functions using familiar `map`, `filter`, `reduce`, etc.
-- Transformations are lazy and are only performed item-by-item when the final
-- iterator is consumed.

local exports = {}

-- ## Create Iterators
--
-- These functions help you create iterators from tables.

-- Create the metatable we use for `iter_values` below.
local _iter_values_of = {}
function _iter_values_of.__call(self)
  if not self.is_exhausted then
    local i, v = self.next(self.state, self.i)
    if not i then
      self.is_exhausted = true
    else
      self.i = i
      return v
    end
  end
end

-- Capture the state of a stateless iterator and return a stateful iterator
-- which will only return values. This is a lower-level function. You'll
-- typically want to use `ivalues` or `values` instead.
local function iter_values_of(next, state, i)
  local iter = {next=next, state=state, i=i, is_exhausted=false}
  return setmetatable(iter, _iter_values_of)
end
exports.iter_values_of = iter_values_of

-- Iterate over the indexed values of a table.
-- Returns a stateful iterator that yields single values.
--
-- Example:
--
--     local t = {1, 2, 3}
--     local x = ivalues(t)
--     for v in x do print(v) end
local function ivalues(t)
  return iter_values_of(ipairs(t))
end
exports.ivalues = ivalues

-- Iterate over the keyed values of a table.
-- Returns a stateful iterator function that returns one value.
--
-- Example:
--
--     local t = {a=1, b=2, c=3}
--     local x = ivalues(t)
--     for v in x do print(v) end
local function values(t)
  return iter_values_of(pairs(t))
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

-- Like Lua's built-in `next()` function, but works backwards over indexes,
-- from right-to-left.
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
-- Returns a stateful iterator.
local function rev_ivalues(t)
  return iter_values_of(rev_ipairs(t))
end
exports.rev_ivalues = rev_ivalues

-- ## Transform iterators
--
-- These functions will allow you to transform iterators.

-- Apply a filter function to all values of the iterator, returning a new
-- iterator containing only the items that passed the test.
-- `predicate` is a function that returns a boolean value. Anything it returns
-- `true` for is kept.
local function filter(predicate, next)
  return function()
    for v in next do
      if predicate(v) then return v end
    end
  end
end
exports.filter = filter

-- Filter a stateful iterator function, returning an iterator containing only
-- the items that *fail* the test. This function is the compliment of `filter`.
local function remove(predicate, next)
  return function()
    for v in next do
      if not predicate(v) then return v end
    end
  end
end
exports.remove = remove

-- Map each item with function `a2b`, returning a new iterator of mapped values.
--
-- Note that you may also use map to filter values, by returning `nil`.
-- This is useful when adhering to Lua's convention of returning `nil` for
-- function exceptions. Failures are automatically filtered out.
--
-- This function can be used to serve a similar purpose to Python's list
-- comprehensions and generator expressions. It lets you write your functions
-- for single values, then have them deal with any iterator sequence,
-- returning a new iterator sequence. Like Python's list comprehensions, you
-- can both map and filter the values (to filter, simply return `nil`).
local function map(a2b, next)
  return function()
    for v in next do
      local xv = a2b(v)
      -- Skip `nil` values, since `nil` terminates iteration in Lua.
      if xv ~= nil then
        return xv
      end
    end
  end
end
exports.map = map

-- Lift a function to become an iterator transformer.
-- Returns a new function that will consume an iterator and return a new
-- iterator, transformed with function `a2b`. Example:
--
--     function square(x) return x * x end
--     local squares = lift(square)
--     local t = {1, 2, 3}
--     local x = iter.ivalues(t)
--     local y = squares(x)
--     -- <1, 4, 9>
local function lift(a2b)
  return function(x)
    return map(a2b, x)
  end
end
exports.lift = lift

-- Step through iterator with a reducing function and a starting `result value`.
-- Returns an iterator for the result at each step of the reduction.
--
-- Example:
--
--     local v = iter.values({1, 2, 3, 4})
--     local function sum(x, y) return x + y end
--     local r = iter.reductions(sum, 0, v)
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

-- Take the first `n` items of iterator.
-- Returns a new iterator that will terminate after yielding `n` items.
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

-- Take items from iterator while `predicate` function returns `true`.
-- As soon as function returns `false`, stop iteration.
local function take_while(predicate, next)
  return function()
    for v in next do
      if predicate(v) then
        return v
      else
        return nil
      end
    end
  end
end
exports.take_while = take_while

-- Skip the first `n` items of iterator.
-- Returns a new iterator that will yield items after skipping `n` items.
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

-- Skip items until `predicate` function returns true.
-- Returns a new iterator with items after `predicate` returns true.
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
exports.skip_while = skip_while

-- Partition an iterator into "chunks", returning an iterator of tables
-- containing `chunk_size` items each.
-- Returns a new iterator of chunks.
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

-- Remove adjacent duplicates from iterator. Values are compared with `compare`
-- function. Function gets previous and current value. If it returns true, the
-- pair is not considered to be a duplicate.
local function dedupe_with(compare, next)
  local prev = dedupe
  return function()
    for curr in next do
      if compare(prev, curr) then
        prev = curr
        return curr
      end
    end
  end
end
exports.dedupe_with = dedupe_with

-- ## Reduce Iterators
--
-- These functions let you consume iterators, and transform them into a value.

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

local function add(a, b)
  return a + b
end
exports.add = add

-- Sum over all of the values of iterator `next`, starting with number `start`.
-- Example:
--
--     local t = {1, 2, 3}
--     local x = iter.ivalues(t)
--     local n = iter.sum(10, x)
--     -- 16
local function sum(start, next)
  return reduce(add, start, next)
end
exports.sum = sum

local function append(t, v)
  table.insert(t, v)
  return t
end
exports.append = append

-- Insert values from iterator into table `t`.
-- Mutates and returns `t`.
local function extend(t, next)
  return reduce(append, t, next)
end
exports.extend = extend

-- Collect an iterator's values into a table.
-- Typical iterator workflow is to transform iterators, then collect the result.
-- Example:
--
--     local x = iter.ivalues({1, 2, 3, 4, 5})
--     local chunks = partition(3, x)
--     local t = collect(chunks)
--     print(t) -- {{1, 2, 3}, {4, 5}}
local function collect(next)
  return extend({}, next)
end
exports.collect = collect

local function compare_min(x, y)
  if x and x < y then
    return x
  else
    return y
  end
end

-- Get the smallest number in the iterator.
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

-- Get the largest number in the iterator.
local function max(next, ...)
  return reduce(compare_max, nil, next, ...)
end
exports.max = max

-- Search through iterator `next`, and return the first value that passes
-- the `predicate` function.
local function find(predicate, next)
  for v in next do
    if predicate(v) then
      return v
    end
  end
end
exports.find = find

return exports