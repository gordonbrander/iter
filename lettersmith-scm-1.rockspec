package = "iter"
version = "scm-1"
source = {
  url = "git://github.com/gordonbrander/iter"
}
description = {
  summary = "Map, filter and transform lazy iterators",
  detailed = [[
  iter offers the familiar `map()`, `filter()`, etc with a twist: it transforms
  iterators lazily, without creating intermediate tables for results.
  ]],
  homepage = "https://github.com/gordonbrander/lettersmith",
  license = "MIT/X11"
}
build = {
  type = "builtin",
  modules = {
    ["iter"] = "iter.lua"
  }
}
