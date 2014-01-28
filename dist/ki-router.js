/*

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
*/


(function() {
  "use strict";
  var KiRouter, KiRoutes, SinatraRouteParser,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  KiRouter = {};

  KiRouter.version = '1.1.9';

  if (typeof module !== "undefined" && module !== null) {
    module.exports = KiRouter;
    KiRouter.KiRouter = KiRouter;
  } else {
    if ((typeof define !== "undefined" && define !== null) && (define.amd != null)) {
      define([], function() {
        return KiRouter;
      });
    }
    this.KiRouter = KiRouter;
  }

  KiRouter.router = function() {
    return new KiRoutes();
  };

  KiRoutes = (function() {
    function KiRoutes() {
      this.addListener = __bind(this.addListener, this);
      this.updateUrl = __bind(this.updateUrl, this);
      this.renderUrl = __bind(this.renderUrl, this);
      this.renderInitialView = __bind(this.renderInitialView, this);
      this.attachLocationChangeListener = __bind(this.attachLocationChangeListener, this);
      this.fixTargetPort = __bind(this.fixTargetPort, this);
      this.fixUsername = __bind(this.fixUsername, this);
      this.targetHostSame = __bind(this.targetHostSame, this);
      this.targetAttributeIsCurrentWindow = __bind(this.targetAttributeIsCurrentWindow, this);
      this.metakeyPressed = __bind(this.metakeyPressed, this);
      this.findATag = __bind(this.findATag, this);
      this.leftMouseButton = __bind(this.leftMouseButton, this);
      this.blog = __bind(this.blog, this);
      this.disableEventDefault = __bind(this.disableEventDefault, this);
      this.attachClickListener = __bind(this.attachClickListener, this);
      this.historyApiRouting = __bind(this.historyApiRouting, this);
      this.hashbangRouting = __bind(this.hashbangRouting, this);
      this.transparentRouting = __bind(this.transparentRouting, this);
      this.addPostExecutionListener = __bind(this.addPostExecutionListener, this);
      this.find = __bind(this.find, this);
      this.exec = __bind(this.exec, this);
      this.add = __bind(this.add, this);
      this.log = __bind(this.log, this);
    }

    KiRoutes.prototype.routes = [];

    KiRoutes.prototype.postExecutionListeners = [];

    KiRoutes.prototype.debug = false;

    KiRoutes.prototype.log = function() {
      if (this.debug && console && console.log) {
        if (JSON.stringify) {
          return console.log("ki-router: " + JSON.stringify(arguments));
        } else {
          return console.log(arguments);
        }
      }
    };

    KiRoutes.prototype.add = function(urlPattern, fn, metadata) {
      return this.routes.push({
        route: new SinatraRouteParser(urlPattern),
        fn: fn,
        urlPattern: urlPattern,
        metadata: metadata
      });
    };

    KiRoutes.prototype.exec = function(path) {
      var listener, matched, _i, _len, _ref;
      if (matched = this.find(path)) {
        this.log("Found route for", path, " Calling function with params ", matched.params);
        matched.result = matched.fn(matched.params);
        _ref = this.postExecutionListeners;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          listener = _ref[_i];
          listener(matched, this.previous);
        }
        this.previous = matched;
        return matched;
      }
    };

    KiRoutes.prototype.find = function(path) {
      var candidate, params, _i, _len, _ref;
      _ref = this.routes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        candidate = _ref[_i];
        if (params = candidate.route.parse(path, this.paramVerifier)) {
          return {
            params: params,
            route: candidate.matchedRoute,
            fn: candidate.fn,
            urlPattern: candidate.urlPattern,
            path: path,
            metadata: candidate.metadata
          };
        }
      }
    };

    KiRoutes.prototype.addPostExecutionListener = function(fn) {
      return this.postExecutionListeners.push(fn);
    };

    KiRoutes.prototype.pushStateSupport = history && history.pushState;

    KiRoutes.prototype.hashchangeSupport = "onhashchange" in window;

    KiRoutes.prototype.hashBaseUrl = false;

    KiRoutes.prototype.previous = false;

    KiRoutes.prototype.disableUrlUpdate = false;

    KiRoutes.prototype.fallbackRoute = false;

    KiRoutes.prototype.init = false;

    KiRoutes.prototype.paramVerifier = false;

    KiRoutes.prototype.transparentRouting = function() {
      this.init = true;
      try {
        this.attachClickListener();
        this.attachLocationChangeListener();
        return this.renderInitialView();
      } finally {
        this.init = false;
      }
    };

    KiRoutes.prototype.hashbangRouting = function() {
      this.pushStateSupport = false;
      if (!this.hashchangeSupport) {
        throw new Error("No hashchange support!");
      }
      return this.transparentRouting();
    };

    KiRoutes.prototype.historyApiRouting = function() {
      this.hashchangeSupport = false;
      return this.transparentRouting();
    };

    KiRoutes.prototype.attachClickListener = function() {
      var _this = this;
      if (this.pushStateSupport || this.hashchangeSupport) {
        return this.addListener(document, "click", function(event) {
          var aTag, href, target;
          event = event || window.event;
          target = event.target || event.srcElement;
          if (target) {
            _this.log("Checking if click event should be rendered");
            aTag = _this.findATag(target);
            if (_this.blog("- A tag", aTag) && _this.blog("- Left mouse button click", _this.leftMouseButton(event)) && _this.blog("- Not meta keys pressed", !_this.metakeyPressed(event)) && _this.blog("- Target attribute is current window", _this.targetAttributeIsCurrentWindow(aTag)) && _this.blog("- Link host same as current window", _this.targetHostSame(aTag))) {
              href = aTag.attributes.href.nodeValue;
              _this.log("Click event passed all checks");
              if (!_this.pushStateSupport && _this.hashchangeSupport && _this.hashBaseUrl && _this.hashBaseUrl !== window.location.pathname) {
                _this.log("Using hashbang change to trigger rendering for", href);
                _this.disableEventDefault(event);
                window.location.href = _this.hashBaseUrl + "#!" + href;
                return;
              }
              if (_this.exec(href)) {
                _this.log("Rendered", href);
                _this.disableEventDefault(event);
                return _this.updateUrl(href);
              } else {
                return _this.log("Letting browser render url because no matching route", href);
              }
            }
          }
        });
      }
    };

    KiRoutes.prototype.disableEventDefault = function(ev) {
      if (ev.preventDefault) {
        return ev.preventDefault();
      } else {
        return ev.returnValue = false;
      }
    };

    KiRoutes.prototype.blog = function(str, v) {
      this.log(str + ", result: " + v);
      return v;
    };

    KiRoutes.prototype.leftMouseButton = function(event) {
      return (event.which != null) && event.which === 1 || event.button === 0;
    };

    KiRoutes.prototype.findATag = function(target) {
      while (target) {
        if (target.tagName === "A") {
          return target;
        }
        target = target.parentElement;
      }
      return false;
    };

    KiRoutes.prototype.metakeyPressed = function(event) {
      return event.shiftKey || event.ctrlKey || event.altKey || event.metaKey;
    };

    KiRoutes.prototype.targetAttributeIsCurrentWindow = function(aTag) {
      var val;
      if (!aTag.attributes.target) {
        return true;
      }
      val = aTag.attributes.target.nodeValue;
      if (["_blank", "_parent"].indexOf(val) !== -1) {
        return false;
      }
      if (val === "_self") {
        return true;
      }
      if (val === "_top") {
        return window.self === window.top;
      }
      return val === window.name;
    };

    KiRoutes.prototype.targetHostSame = function(aTag) {
      var l, targetPort, targetUserName;
      l = window.location;
      targetUserName = this.fixUsername(aTag.username);
      targetPort = this.fixTargetPort(aTag.port, aTag.protocol);
      return aTag.hostname === l.hostname && targetPort === l.port && aTag.protocol === l.protocol && targetUserName === l.username && aTag.password === aTag.password;
    };

    KiRoutes.prototype.fixUsername = function(username) {
      if (username === "") {
        return void 0;
      } else {
        return username;
      }
    };

    KiRoutes.prototype.fixTargetPort = function(port, protocol) {
      var protocolPorts;
      protocolPorts = {
        "http:": "80",
        "https:": "443"
      };
      if (port !== "" && port === protocolPorts[protocol]) {
        return "";
      } else {
        return port;
      }
    };

    KiRoutes.prototype.attachLocationChangeListener = function() {
      var _this = this;
      if (this.pushStateSupport) {
        return this.addListener(window, "popstate", function(event) {
          var href;
          href = window.location.pathname;
          _this.log("Rendering onpopstate", href);
          return _this.renderUrl(href);
        });
      } else {
        if (this.hashchangeSupport) {
          return this.addListener(window, "hashchange", function(event) {
            var href;
            if (window.location.hash.substring(0, 2) === "#!") {
              href = window.location.hash.substring(2);
              if (!_this.previous || href !== _this.previous.path) {
                _this.log("Rendering onhashchange", href);
                return _this.renderUrl(href);
              }
            }
          });
        }
      }
    };

    KiRoutes.prototype.renderInitialView = function() {
      var initialUrl;
      this.log("Rendering initial page");
      initialUrl = window.location.pathname;
      if (this.pushStateSupport) {
        if (window.location.hash.substring(0, 2) === "#!" && this.find(window.location.hash.substring(2))) {
          initialUrl = window.location.hash.substring(2);
        }
      } else {
        if (this.hashchangeSupport) {
          if (window.location.hash.substring(0, 2) === "#!") {
            initialUrl = window.location.hash.substring(2);
          }
        }
      }
      return this.renderUrl(initialUrl);
    };

    KiRoutes.prototype.renderUrl = function(url) {
      var err, ret;
      try {
        if (ret = this.exec(url)) {
          return ret;
        } else {
          if (this.fallbackRoute) {
            return this.fallbackRoute(url);
          } else {
            return this.log("Could not resolve route for", url);
          }
        }
      } catch (_error) {
        err = _error;
        return this.log("Could not resolve route for", url, " exception", err);
      }
    };

    KiRoutes.prototype.updateUrl = function(href) {
      if (!this.disableUrlUpdate) {
        if (this.pushStateSupport) {
          return history.pushState({}, document.title, href);
        } else {
          if (this.hashchangeSupport) {
            return window.location.hash = "!" + href;
          }
        }
      }
    };

    KiRoutes.prototype.addListener = function(element, event, fn) {
      if (element.addEventListener) {
        return element.addEventListener(event, fn, false);
      } else if (element.attachEvent) {
        return element.attachEvent("on" + event, fn);
      } else {
        return raise("addListener can not attach listeners!");
      }
    };

    return KiRoutes;

  })();

  SinatraRouteParser = (function() {
    function SinatraRouteParser(route) {
      this.parse = __bind(this.parse, this);
      var firstMatch, match, pattern, routeItems, segment, segments, _i, _len;
      this.keys = [];
      route = route.substring(1);
      segments = [];
      routeItems = route.split("/");
      for (_i = 0, _len = routeItems.length; _i < _len; _i++) {
        segment = routeItems[_i];
        match = segment.match(/((:\w+)|\*)/);
        if (match) {
          firstMatch = match[0];
          if (firstMatch === "*") {
            this.keys.push("splat");
            segment = "(.*)";
          } else {
            this.keys.push(firstMatch.substring(1));
            segment = "([^\/?#]+)";
          }
        }
        segments.push(segment);
      }
      pattern = "^/" + segments.join("/") + "$";
      this.pattern = new RegExp(pattern);
    }

    SinatraRouteParser.prototype.parse = function(path, paramVerify) {
      var i, key, match, matches, ret, _i, _len, _ref;
      matches = path.match(this.pattern);
      if (matches) {
        i = 0;
        ret = {};
        _ref = matches.slice(1);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          match = _ref[_i];
          if (paramVerify && !paramVerify(match)) {
            return false;
          }
          key = this.keys[i];
          i += 1;
          this.append(ret, key, match);
        }
        return ret;
      }
    };

    SinatraRouteParser.prototype.append = function(h, key, value) {
      var old;
      if (old = h[key]) {
        if (!this.typeIsArray(old)) {
          h[key] = [old];
        }
        return h[key].push(value);
      } else {
        return h[key] = value;
      }
    };

    SinatraRouteParser.prototype.typeIsArray = function(value) {
      return value && typeof value === 'object' && value instanceof Array && typeof value.length === 'number' && typeof value.splice === 'function' && !(value.propertyIsEnumerable('length'));
    };

    return SinatraRouteParser;

  })();

}).call(this);
