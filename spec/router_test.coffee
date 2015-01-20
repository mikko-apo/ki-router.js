"use strict"

eq = (was, expected) ->
  was = JSON.stringify(was)
  expected = JSON.stringify(expected)
  if was != expected
    throw new Error(was + " is not equal to expected " + expected)

window.Zhain.prototype.test = () ->
  me = @
  (done) ->
    me.run (err) ->
      done(err)
      if !err
        if @iframe
          document.body.removeChild(@iframe)
        else if @w
         @w.close()

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

window.Zhain.prototype.window = (url, checker, openInWindow) ->
  return @do (done) ->
    if !@windowName
      @windowName = "test" + Math.random()
      if !openInWindow
        @iframe = document.createElement("iframe")
        @iframe.setAttribute("style", "width: 100%; height: 300px;")
        @iframe.setAttribute("name", @windowName)
        document.body.appendChild(@iframe)
    if !(w = @w = window.open(url, @windowName))
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
  eq([url(w), text(w, "#routerRenderCount"), text(w, "#txt"), text(w, "#pageSame") == "Ok!"],
    [pageUrl, "#{renderCount}", txt, pageSame])

describe "KiRouter", ->
  this.timeout(6000);
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
    it "should render correct view", zhain().
      window("/", (w) -> pState(w, "/", "0", "No path!", false)).
      window("/#/index.html", (w) -> pState(w, "/#/index.html","1","/index.html",false)).
      window("/index.html", (w) -> pState(w, "/index.html","1","/index.html",false)).
      window("/#!/index.html", (w) -> pState(w, "/#!/index.html","1","/index.html",false)).
      test()
    it "should handle click to /foo without reloading page", zhain().
      window("/", (w) -> pState(w, "/", "0", "No path!", false)).
      click("#pageSame", (w) -> pState(w, "/","0","No path!",true)).
      click("#link_foo", (w) -> pState(w, "/foo","1","/foo",true)).
      click("#link_foo", (w) -> pState(w, "/foo","2","/foo",true)).
      click("#link_index", (w) -> pState(w, "/index.html","3","/index.html",true)).
      click("#link_foo", (w) -> pState(w, "/foo","4","/foo",true)).
      back((w) -> pState(w, "/index.html", "5", "/index.html", true)).
      test()
    it "should handle direct link to /#!/foo", zhain().
      window("/#!/foo", (w) -> pState(w, "/#!/foo", "1", "/foo", false)).
      click("#pageSame", (w) -> pState(w, "/#!/foo", "1", "/foo", true)).
      click("#link_foo", (w) -> pState(w, "/foo", "2", "/foo", true)).
      test()
    it "should handle direct link to /#/foo", zhain().
      window("/#/foo", (w) -> pState(w, "/#/foo", "1", "/foo", false)).
      click("#pageSame", (w) -> pState(w, "/#/foo", "1", "/foo", true)).
      click("#link_foo", (w) -> pState(w, "/foo", "2", "/foo", true)).
      test()
  describe "# routes with hashBaseUrl", ->
    it "should handle click to /foo without reloading page", zhain().
      window("/", ((w) -> pState(w, "/", "0", "No path!", false)), false).
      click("#pageSame", (w) -> pState(w, "/","0","No path!",true); w.router.pushStateSupport=false).
      click("#link_foo", (w) -> pState(w, "/index.html#/foo","1","/foo",false)).
      click("#pageSame", (w) -> pState(w, "/index.html#/foo","1","/foo",true); w.router.pushStateSupport=false).
      click("#link_foo", (w) -> pState(w, "/index.html#/foo","2","/foo",true)).
      click("#link_index", (w) -> pState(w, "/index.html#/index.html","3","/index.html",true)).
      click("#link_foo", (w) -> pState(w, "/index.html#/foo","4","/foo",true)).
      back((w) -> pState(w, "/index.html#/index.html", "4", "/foo", true)). # bug, should be 5, /index.html
      test()
