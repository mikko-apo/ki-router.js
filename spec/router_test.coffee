"use strict"

eq = (a, b) ->
  a = JSON.stringify(a)
  b = JSON.stringify(b)
  if a != b
    throw new Error(a + " is not equal to " + b)

window.Zhain.prototype.test = (done) ->
  @end (err) -> done(err)

window.Zhain.prototype.retry = (done, attempts, fn) ->
  try
    fn()
    done()
  catch error
    if attempts == 0
      done(error)
    callback = -> window.Zhain.prototype.retry(done, attempts - 1, fn)
    setTimeout callback, 50

retryCount = 30

window.Zhain.prototype.window_open = (url, checker) ->
  return @do (done) ->
    if !(w = @w = window.open(url, "test_window"))
      throw new Error("Could not open pop-up window. Please enable popups.")
    callback = -> window.Zhain.prototype.retry(done, retryCount, -> checker(w))
    setTimeout callback, 10

window.Zhain.prototype.click = (selector, checker) ->
  return @do (done) ->
    w = @w
    s(w, selector).click()
    window.Zhain.prototype.retry(done, retryCount, -> checker(w))

window.Zhain.prototype.back = (checker) ->
  return @do (done) ->
    w = @w
    w.history.back()
    window.Zhain.prototype.retry(done, retryCount, -> checker(w))

s = (w, selector) ->
  w.document.querySelector(selector)

text = (w, selector) ->
  s(w, selector).innerHTML

url = (w) ->
  w.location.pathname + w.location.hash

pState = (w, pageUrl, renderCount, txt, pageSame) ->
  w.router.initDone
  eq([pageUrl, "#{renderCount}", txt, pageSame],
    [url(w), text(w, "#routerRenderCount"), text(w, "#txt"), text(w, "#pageSame") == "Ok!"])

describe "KiRouter", ->
  describe "should execute operation based on matched matchedRoute", ->
    router = KiRouter.router()
    router.disableUrlUpdate = true
    router.add("/one-name/:name", (params) -> ["one-name", params.name])
    router.add("/two-name/:nameA/:nameB", (params) -> ["two-name", params.nameA, params.nameB])
    router.add("/double-name/:name/:name", (params) -> ["double-name", params.name])
    router.add("/foo/*", (params) -> ["foo", params.splat])
    router.add("/multi/:name/*", (params) -> ["multi", params.name, params.splat])
    router.add("/reverse-multi/*/:name", (params) -> ["reverse-multi", params.splat, params.name])
    router.add("/index.html", (params) -> "ok")
    it "with single named parameter", ->
      eq(router.exec("/one-name/mikko").result, ['one-name', 'mikko'])
    it "with two named parameters", ->
      eq(router.exec("/two-name/mikko/apo").result, ['two-name', 'mikko', "apo"])
    it "with two parameters with same name", ->
      eq(router.exec("/double-name/mikko/apo").result, ['double-name', ['mikko', "apo"]])
    it "with wildcard", ->
      eq(router.exec("/foo/mikko").result, ['foo', 'mikko'])
      eq(router.exec("/foo/mikko/bar").result, ['foo', 'mikko/bar'])
    it "with named parameter and wildcard", ->
      eq(router.exec("/multi/mikko/bar").result, ['multi', 'mikko', 'bar'])
      eq(router.exec("/multi/mikko/foo/bar").result, ['multi', 'mikko', 'foo/bar'])
    it "with wildcard and named parameter", ->
      eq(router.exec("/reverse-multi/bar/mikko").result, ['reverse-multi', 'bar', 'mikko'])
      eq(router.exec("/reverse-multi/foo/bar/mikko").result, ['reverse-multi', 'foo/bar', 'mikko'])
    it "with undefined should return undefined", ->
      eq(router.exec("/i"), undefined)
    it "with urls containg dot", ->
      eq(router.exec("/index.html").result, "ok")
    it "and escape regex dot", ->
      eq(router.exec("/indexahtml"), undefined)
  describe "should provide listeners", ->
    router = KiRouter.router()
    router.disableUrlUpdate = true
    it "for execution results", ->
      results = []
      router.add("/foo", (params) -> "cool!")
      router.addPostExecutionListener((matched, previous) -> results.push(matched.result))
      router.exec("/foo")
      eq(["cool!"], results)
    it "for listening to exceptions", ->
      errors = []
      router.add("/exception", (params) -> throw new Error("uups!"))
      router.addExceptionListener((matched, previous)-> errors.push(matched.error.message))
      try
        router.exec("/exception")
        throw new Error("should have raised an exception!")
      catch
      eq(["uups!"], errors)
  describe "browser integration", ->
    beforeEach (done) ->
      window.open("about:blank", "test_window")
      setTimeout done, 10
    it "should render correct view", zhain().
      window_open("/", (w) -> pState(w, "/", "0", "No path!", false)).
      window_open("/index.html", (w) -> pState(w, "/index.html","1","/index.html",false)).
      test()
    it "should handle click to /foo without reloading page", zhain().
      window_open("/", (w) -> pState(w, "/", "0", "No path!", false)).
      click("#pageSame", (w) -> pState(w, "/","0","No path!",true)).
      click("#link_foo", (w) -> pState(w, "/foo","1","/foo",true)).
      click("#link_index", (w) -> pState(w, "/index.html","2","/index.html",true)).
      click("#link_foo", (w) -> pState(w, "/foo","3","/foo",true)).
      back((w) -> pState(w, "/index.html", "4", "/index.html", true)).
      test()
    it "should handle direct link to /#!/foo", zhain().
      window_open("/#!/foo", (w) -> pState(w, "/#!/foo", "1", "/foo", false)).
      click("#pageSame", (w) -> pState(w, "/#!/foo", "1", "/foo", true)).
      click("#link_foo", (w) -> pState(w, "/foo", "2", "/foo", true)).
      test()
    it "should handle direct link to /#/foo", zhain().
      window_open("/#/foo", (w) -> pState(w, "/#/foo", "1", "/foo", false)).
      click("#pageSame", (w) -> pState(w, "/#/foo", "1", "/foo", true)).
      click("#link_foo", (w) -> pState(w, "/foo", "2", "/foo", true)).
      test()
