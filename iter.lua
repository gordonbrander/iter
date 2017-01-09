--[[
Transform iterator functions using familiar `map`, `filter`, `reduce`, etc.

Can transform any stateful iterator function.
]]--

local exports = {}

-- Capture the state of a stateless iterator and return a stateful iterator
-- of values.
local function stateful(next, state, at)
  local v
  return function()
    at, v = next(state, at)
    return v
  end
end
exports.stateful = stateful

-- Iterate over the values of a table.
-- Returns a stateful iterator function.
local function values(t)
  return stateful(ipairs(t))
end
exports.values = values

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
  return filter(is_nil, map(a2b, next))
end
exports.filter_map

-- Lift a function to become a filter_map iterator transformer.
-- This can be used in a similar way to Python's generator expressions.
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
    n = n - 1
    if n > 0 then return next() end
  end
end
exports.take = take

local function skip(n, next)
  return function()
    for v in next do
      n = n - 1
      if n < 1 then return v end
    end
  end
end
exports.skip = skip

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

-- Collect an iterator's values into a table.
local function collect(next, ...)
  return reduce(append, {}, next, ...)
end
exports.collect = collect

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

return exports