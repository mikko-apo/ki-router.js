"use strict"

eq = (a,b) ->
  if JSON.stringify(a) != JSON.stringify(b)
    throw new Error( JSON.stringify(a) + " is not equal to " + JSON.stringify(b))

window.Zhain.prototype.test = (done) ->
  @end (err) -> done(err)

window.Zhain.prototype.trie = trie = (done, attempts, fn) ->
  try
    fn()
    done()
  catch error
    if attempts == 0
      done(error)
    callback = -> window.Zhain.prototype.trie(done, attempts-1, fn)
    setTimeout callback, 10

window.Zhain.prototype.window_open = (url, checker) ->
  return @do (done) ->
    w = @w = window.open(url, "test_window")
    if !w
      throw new Error("Could not open pop-up window. Please enable popups.")
    window.Zhain.prototype.trie(done, 100, -> checker(w))

window.Zhain.prototype.click = (selector, checker) ->
  return @do (done) ->
    w = @w
    s(w, selector).click()
    window.Zhain.prototype.trie(done, 100, -> checker(w))

s = (w, selector) ->
  w.document.querySelector(selector)

text = (w, selector) ->
  s(w, selector).innerHTML

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
  describe "should provide listeners", ->
    router = KiRouter.router()
    router.disableUrlUpdate=true
    it "for execution results", ->
      results = []
      router.add("/foo", (params) -> "cool!")
      router.addPostExecutionListener( (matched, previous) -> results.push(matched.result) )
      router.exec("/foo")
      eq(["cool!"], results)
    it "for listening to exceptions", ->
      errors = []
      router.add("/exception", (params) -> throw new Error("uups!"))
      router.addExceptionListener( (matched, previous)-> errors.push(matched.error.message) )
      try
        router.exec("/exception")
        throw new Error("should have raised an exception!")
      catch
      eq(["uups!"], errors)
  describe "browser integration", ->
    beforeEach ->
      window.open("about:blank", "test_window")
    it "should render correct view", zhain().
      window_open("/", (w) -> w.router.initDone; eq("No clicks!", text(w, "#txt"))).
      window_open("/index.html", (w) -> w.router.initDone; eq(["/index.html", "1"], [text(w, "#txt"), text(w, "#routerRenderCount")])).
      test()
    it "should handle click to /foo without reloading page", zhain().
      window_open("/", (w) -> w.router.initDone; eq("No clicks!", text(w, "#txt"))).
      click("#pageSame", (w) -> eq("Ok!", text(w, "#pageSame"))).
      click("#link_foo", (w) -> eq(["Ok!", "/foo", "1"], [text(w, "#pageSame"), text(w, "#txt"), text(w, "#routerRenderCount")])).
      test()
