"use strict"

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
    it "with single named parameter", ->
      router.exec("/one-name/mikko").result.should.deep.equal [ 'one-name', 'mikko' ]
    it "with two named parameters", ->
      router.exec("/two-name/mikko/apo").result.should.deep.equal [ 'two-name', 'mikko', "apo" ]
    it "with two parameters with same name", ->
      router.exec("/double-name/mikko/apo").result.should.deep.equal [ 'double-name', ['mikko', "apo"] ]
    it "with wildcard", ->
      router.exec("/foo/mikko").result.should.deep.equal [ 'foo', 'mikko' ]
      router.exec("/foo/mikko/bar").result.should.deep.equal [ 'foo', 'mikko/bar' ]
    it "with named parameter and wildcard", ->
      router.exec("/multi/mikko/bar").result.should.deep.equal [ 'multi', 'mikko', 'bar' ]
      router.exec("/multi/mikko/foo/bar").result.should.deep.equal [ 'multi', 'mikko', 'foo/bar' ]
    it "with wildcard and named parameter", ->
      router.exec("/reverse-multi/bar/mikko").result.should.deep.equal [ 'reverse-multi', 'bar', 'mikko' ]
      router.exec("/reverse-multi/foo/bar/mikko").result.should.deep.equal [ 'reverse-multi', 'foo/bar' ,'mikko' ]
