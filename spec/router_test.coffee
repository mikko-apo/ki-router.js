"use strict"

eq = (a,b) ->
  if JSON.stringify(a) != JSON.stringify(b)
    throw new Error( JSON.stringify(a) + " is not equal to " + JSON.stringify(b))

describe "KiRouter", ->
  describe "should execute operation based on matched matchedRoute", ->
    router = KiRouter.router()
    router.disableUrlUpdate=true
    router.add("/one-name/:name", (params) -> ["one-name", params.name] )
    router.add("/two-name/:nameA/:nameB", (params) -> ["two-name", params.nameA, params.nameB] )
    router.add("/double-name/:name/:name", (params) -> ["double-name", params.name] )
    router.add("/foo/*", (params) -> ["foo", params.splat] )
    router.add("/multi/:name/*", (params) -> ["multi", params.name, params.splat] )
    router.add("/reverse-multi/*/:name", (params) -> ["reverse-multi", params.splat, params.name] )
    router.add("/index.html", (params) -> "ok")
    it "with single named parameter", ->
      eq(router.exec("/one-name/mikko").result, [ 'one-name', 'mikko' ])
    it "with two named parameters", ->
      eq(router.exec("/two-name/mikko/apo").result, [ 'two-name', 'mikko', "apo" ])
    it "with two parameters with same name", ->
      eq(router.exec("/double-name/mikko/apo").result, [ 'double-name', ['mikko', "apo"] ])
    it "with wildcard", ->
      eq(router.exec("/foo/mikko").result, [ 'foo', 'mikko' ])
      eq(router.exec("/foo/mikko/bar").result, [ 'foo', 'mikko/bar' ])
    it "with named parameter and wildcard", ->
      eq(router.exec("/multi/mikko/bar").result, [ 'multi', 'mikko', 'bar' ])
      eq(router.exec("/multi/mikko/foo/bar").result, [ 'multi', 'mikko', 'foo/bar' ])
    it "with wildcard and named parameter", ->
      eq(router.exec("/reverse-multi/bar/mikko").result, [ 'reverse-multi', 'bar', 'mikko' ])
      eq(router.exec("/reverse-multi/foo/bar/mikko").result, [ 'reverse-multi', 'foo/bar' ,'mikko' ])
    it "with undefined should return undefined", ->
      eq(router.exec("/i"), undefined)
    it "with urls containg dot", ->
      eq(router.exec("/index.html").result, "ok")
    it "and escape regex dot", ->
      eq(router.exec("/indexahtml"), undefined)
