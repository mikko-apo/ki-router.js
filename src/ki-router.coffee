###

Copyright 2012-2013 Mikko Apo

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

###

"use strict"

# Missing features:
# - $("a").click does not register but $("a")[0].click does
# - more complete sinatra path parsing, JavascriptRouteParser
# - test suite
# - documentation
# Possible features
# - clarify when fallbackRoute is used or if it is needed
# - postExecutionListener gets access to exception during exec
# - executed function gets access to full matched information
# - relative url support is tricky to get right. What if application is served urls with splat?
# - querystring parameters as part of params. How should they interract with #! support?
# - form support, catch form submits (how would this work?) get / post?
# - chrome fails when converting plain url to hashbang url: %23, window.location.hash escaping
# - navigate
# - go
# Known issues:
# - hashbang urls don't work in a href tags -> won't fix, use /plain/urls
# - does not resolve situation hashbang url needs to be converted and both window.location.pathname and window.location.hash are defined

KiRouter = {}
KiRouter.version = '<version>'

if module?
  module.exports = KiRouter # for KiRouter = require 'KiRouterjs'
  KiRouter.KiRouter = KiRouter # for {KiRouter} = require 'KiRouterjs'
else
  if define? and define.amd?
    define [], -> KiRouter
  @KiRouter = KiRouter # otherwise for execution context

KiRouter.router = -> new KiRoutes()

class KiRoutes
  routes: []
  postExecutionListeners: []
  debug: false
  log: =>
    if @debug && console && console.log
      console.log(arguments)
  add: (urlPattern, fn, metadata) =>
    @routes.push({route: new SinatraRouteParser(urlPattern), fn: fn, urlPattern: urlPattern, metadata: metadata})
  exec: (path) =>
    if matched = @find(path)
      @log("Found route for", path, " Calling function with params ", matched.params)
      matched.result = matched.fn(matched.params)
      for listener in @postExecutionListeners
        listener(matched, @previous)
      @previous = matched
      return matched
  find: (path) =>
    for candidate in @routes
      if params = candidate.route.parse(path, @paramVerifier)
        return {params: params, route: candidate.matchedRoute, fn: candidate.fn, urlPattern: candidate.urlPattern, path: path, metadata: candidate.metadata}
  addPostExecutionListener: (fn) =>
    @postExecutionListeners.push(fn)

  pushStateSupport: history && history.pushState
  hashchangeSupport: "onhashchange" of window
  hashBaseUrl: false
  previous: false
  disableUrlUpdate: false
  fallbackRoute: false
  init: false
  paramVerifier: false
  transparentRouting: () =>
    @init = true
    try
      @attachClickListener()
      @attachLocationChangeListener()
      @renderInitialView()
    finally
      @init = false
  hashbangRouting: () =>
    @pushStateSupport = false
    if !@hashchangeSupport
      throw new Error("No hashchange support!")
    @transparentRouting()

  attachClickListener: =>
    if @pushStateSupport || @hashchangeSupport
      @addListener document, "click", (event) =>
        target = event.target
        if target
          @log("Checking if click event should be rendered")
          aTag = @findATag(target)
          if @blog("- A tag", aTag) &&
          @blog("- Left mouse button click", @leftMouseButton(event)) &&
          @blog("- Not meta keys pressed", !@metakeyPressed(event)) &&
          @blog("- Target attribute is current window", @targetAttributeIsCurrentWindow(aTag)) &&
          @blog("- Link host same as current window", @targetHostSame(aTag))
            href = aTag.attributes.href.nodeValue
            @log("Click event passed all checks, rendering ", href)
            if !@pushStateSupport && @hashchangeSupport && @hashBaseUrl && @hashBaseUrl != window.location.pathname
              @log("Using hashbang change to trigger rendering")
              event.preventDefault();
              window.location.href = @hashBaseUrl + "#!" + href
              return
            if @exec(href)
              @log("New url", href)
              event.preventDefault();
              @updateUrl(href)

  blog: (str, v) =>
    @log(str + ", result: " + v)
    v

  leftMouseButton: (event) =>
    event.which? && event.which == 1 || event.button == 0

  findATag: (target) =>
    while target
      if target.tagName == "A"
        return target
      target = target.parentElement
    false

  metakeyPressed: (event) =>
    (event.shiftKey || event.ctrlKey || event.altKey || event.metaKey)

  targetAttributeIsCurrentWindow: (aTag) =>
    if !aTag.attributes.target
      return true
    val = aTag.attributes.target.nodeValue
    if ["_blank", "_parent"].indexOf(val) != -1
      return false
    if val == "_self"
      return true
    if val == "_top"
      return window.self == window.top
    return val == window.name

  targetHostSame: (aTag) =>
    l = window.location
    # Firefox 26 sets aTag.username to "", other browsers use undefined
    targetUserName = aTag.username
    if targetUserName == ""
      targetUserName = undefined
    aTag.host == l.host && aTag.protocol == l.protocol && targetUserName == l.username && aTag.password == aTag.password

  attachLocationChangeListener: =>
    if @pushStateSupport
      @addListener window, "popstate", (event) =>
        href = window.location.pathname
        @log("Rendering onpopstate", href)
        @renderUrl(href)
    else
      if @hashchangeSupport
        @addListener window, "hashchange", (event) =>
          if window.location.hash.substring(0, 2) == "#!"
            href = window.location.hash.substring(2)
            if !@previous || href != @previous.path
              @log("Rendering onhashchange", href)
              @renderUrl(href)

  renderInitialView: =>
    @log("Rendering initial page")
    initialUrl = window.location.pathname
    if @pushStateSupport
      if window.location.hash.substring(0, 2) == "#!" && @find(window.location.hash.substring(2))
        initialUrl = window.location.hash.substring(2)
    else
      if @hashchangeSupport
        if window.location.hash.substring(0, 2) == "#!"
          initialUrl = window.location.hash.substring(2)
    @renderUrl(initialUrl)

  renderUrl: (url) =>
    try
      if ret = @exec(url)
        return ret
      else
        if @fallbackRoute
          return @fallbackRoute(url)
        else
          @log("Could not resolve route for", url)
    catch err
      @log("Could not resolve route for", url, " exception", err)

  updateUrl: (href) =>
    if !@disableUrlUpdate
      if @pushStateSupport
        history.pushState({ }, document.title, href)
      else
        if @hashchangeSupport
          window.location.hash = "!" + href

  addListener: (element, event, fn) =>
    if element.addEventListener  # W3C DOM
      element.addEventListener(event, fn, false);
    else if (element.attachEvent) # // IE DOM
      element.attachEvent("on"+event, fn);
    else
      raise "addListener can not attach listeners!"

class SinatraRouteParser
  constructor: (route) ->
    @keys = []
    route = route.substring(1)
    segments = route.split("/").map (segment) =>
      match = segment.match(/((:\w+)|\*)/)
      if match
        firstMatch = match[0]
        if firstMatch == "*"
          @keys.push "splat"
          "(.*)"
        else
          @keys.push firstMatch.substring(1)
          "([^\/?#]+)"
      else
        segment
    pattern = "^/" + segments.join("/") + "$"
    #    console.log("Pattern", pattern)
    @pattern = new RegExp(pattern)
  parse: (path, paramVerify) =>
    matches = path.match(@pattern)
    #    console.log("Parse", path, matches)
    if matches
      i = 0
      ret = {}
      for match in matches.slice(1)
        if paramVerify && !paramVerify(match)
          return false # parameter did not pass verifier -> abort
        key = @keys[i]
        i+=1
        #        console.log("Found item", match, key)
        @append(ret, key, match)
      ret
  append: (h, key, value) ->
    if old = h[key]
      if !@typeIsArray(old)
        h[key] = [old]
      h[key].push(value)
    else
      h[key]=value
  typeIsArray: ( value ) ->
    value and
    typeof value is 'object' and
    value instanceof Array and
    typeof value.length is 'number' and
    typeof value.splice is 'function' and
    not ( value.propertyIsEnumerable 'length' )
