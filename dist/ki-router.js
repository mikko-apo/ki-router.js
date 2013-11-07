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
      this.targetHostSame = __bind(this.targetHostSame, this);
      this.targetAttributeIsCurrentWindow = __bind(this.targetAttributeIsCurrentWindow, this);
      this.metakeyPressed = __bind(this.metakeyPressed, this);
      this.findATag = __bind(this.findATag, this);
      this.leftMouseButton = __bind(this.leftMouseButton, this);
      this.attachClickListener = __bind(this.attachClickListener, this);
      this.hashbangRouting = __bind(this.hashbangRouting, this);
      this.transparentRouting = __bind(this.transparentRouting, this);
      this.find = __bind(this.find, this);
      this.exec = __bind(this.exec, this);
      this.add = __bind(this.add, this);
      this.log = __bind(this.log, this);
    }

    KiRoutes.prototype.routes = [];

    KiRoutes.prototype.debug = false;

    KiRoutes.prototype.log = function() {
      if (this.debug) {
        return console.log.apply(this, arguments);
      }
    };

    KiRoutes.prototype.add = function(urlPattern, fn) {
      return this.routes.push({
        route: new SinatraRouteParser(urlPattern),
        fn: fn,
        urlPattern: urlPattern
      });
    };

    KiRoutes.prototype.exec = function(path) {
      var matchedRoute;
      if (matchedRoute = this.find(path)) {
        this.log("Found route for", path, " Calling function with params ", matchedRoute.params);
        matchedRoute.result = matchedRoute.fn(matchedRoute.params);
        return matchedRoute;
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
            urlPattern: candidate.urlPattern
          };
        }
      }
    };

    KiRoutes.prototype.pushStateSupport = history && history.pushState;

    KiRoutes.prototype.hashchangeSupport = "onhashchange" in window;

    KiRoutes.prototype.hashBaseUrl = false;

    KiRoutes.prototype.previousView = false;

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

    KiRoutes.prototype.attachClickListener = function() {
      var _this = this;
      if (this.pushStateSupport || this.hashchangeSupport) {
        return this.addListener(document, "click", function(event) {
          var aTag, href, target;
          target = event.target;
          if (target) {
            aTag = _this.findATag(target);
            if (aTag && _this.leftMouseButton(event) && !_this.metakeyPressed(event) && _this.targetAttributeIsCurrentWindow(aTag) && _this.targetHostSame(aTag)) {
              href = aTag.attributes.href.nodeValue;
              _this.log("Processing click", href);
              if (_this.exec(href)) {
                _this.log("New url", href);
                event.preventDefault();
                _this.previousView = href;
                return _this.updateUrl(href);
              }
            }
          }
        });
      }
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
      return null;
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
      var l;
      l = window.location;
      return aTag.host === l.host && aTag.protocol === l.protocol && aTag.username === l.username && aTag.password === aTag.password;
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
              if (href !== _this.previousView) {
                _this.log("Rendering onhashchange", href);
                return _this.renderUrl(href);
              }
            }
          });
        }
      }
    };

    KiRoutes.prototype.renderInitialView = function() {
      var forceUrlUpdate, initialUrl;
      this.log("Rendering initial page");
      initialUrl = window.location.pathname;
      forceUrlUpdate = false;
      if (this.pushStateSupport) {
        if (window.location.hash.substring(0, 2) === "#!" && this.find(window.location.hash.substring(2))) {
          forceUrlUpdate = initialUrl = window.location.hash.substring(2);
        }
      } else {
        if (this.hashchangeSupport) {
          if (window.location.hash === "" && this.find(initialUrl)) {
            if (this.hashBaseUrl && this.hashBaseUrl !== initialUrl) {
              window.location.href = this.hashBaseUrl + "#!" + initialUrl;
            } else {
              window.location.hash = "!" + initialUrl;
            }
          }
          if (window.location.hash.substring(0, 2) === "#!") {
            initialUrl = window.location.hash.substring(2);
          }
        }
      }
      this.renderUrl(initialUrl);
      if (forceUrlUpdate) {
        return this.updateUrl(forceUrlUpdate);
      }
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
      var pattern, segments,
        _this = this;
      this.keys = [];
      route = route.substring(1);
      segments = route.split("/").map(function(segment) {
        var firstMatch, match;
        match = segment.match(/((:\w+)|\*)/);
        if (match) {
          firstMatch = match[0];
          if (firstMatch === "*") {
            _this.keys.push("splat");
            return "(.*)";
          } else {
            _this.keys.push(firstMatch.substring(1));
            return "([^\/?#]+)";
          }
        } else {
          return segment;
        }
      });
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
            return null;
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
