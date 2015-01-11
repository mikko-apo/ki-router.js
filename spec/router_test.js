(function() {
  "use strict";
  var eq, pState, retryCount, s, text, url;

  eq = function(a, b) {
    a = JSON.stringify(a);
    b = JSON.stringify(b);
    if (a !== b) {
      throw new Error(a + " is not equal to " + b);
    }
  };

  window.Zhain.prototype.test = function(done) {
    return this.end(function(err) {
      return done(err);
    });
  };

  window.Zhain.prototype.retry = function(done, attempts, fn) {
    var callback, error;
    try {
      fn();
      return done();
    } catch (_error) {
      error = _error;
      if (attempts === 0) {
        done(error);
      }
      callback = function() {
        return window.Zhain.prototype.retry(done, attempts - 1, fn);
      };
      return setTimeout(callback, 50);
    }
  };

  retryCount = 30;

  window.Zhain.prototype.window_open = function(url, checker) {
    return this["do"](function(done) {
      var callback, w;
      if (!(w = this.w = window.open(url, "test_window"))) {
        throw new Error("Could not open pop-up window. Please enable popups.");
      }
      callback = function() {
        return window.Zhain.prototype.retry(done, retryCount, function() {
          return checker(w);
        });
      };
      return setTimeout(callback, 10);
    });
  };

  window.Zhain.prototype.click = function(selector, checker) {
    return this["do"](function(done) {
      var w;
      w = this.w;
      s(w, selector).click();
      return window.Zhain.prototype.retry(done, retryCount, function() {
        return checker(w);
      });
    });
  };

  window.Zhain.prototype.back = function(checker) {
    return this["do"](function(done) {
      var w;
      w = this.w;
      w.history.back();
      return window.Zhain.prototype.retry(done, retryCount, function() {
        return checker(w);
      });
    });
  };

  s = function(w, selector) {
    return w.document.querySelector(selector);
  };

  text = function(w, selector) {
    return s(w, selector).innerHTML;
  };

  url = function(w) {
    return w.location.pathname + w.location.hash;
  };

  pState = function(w, pageUrl, renderCount, txt, pageSame) {
    w.router.initDone;
    return eq([pageUrl, "" + renderCount, txt, pageSame], [url(w), text(w, "#routerRenderCount"), text(w, "#txt"), text(w, "#pageSame") === "Ok!"]);
  };

  describe("KiRouter", function() {
    describe("should execute operation based on matched matchedRoute", function() {
      var router;
      router = KiRouter.router();
      router.disableUrlUpdate = true;
      router.add("/one-name/:name", function(params) {
        return ["one-name", params.name];
      });
      router.add("/two-name/:nameA/:nameB", function(params) {
        return ["two-name", params.nameA, params.nameB];
      });
      router.add("/double-name/:name/:name", function(params) {
        return ["double-name", params.name];
      });
      router.add("/foo/*", function(params) {
        return ["foo", params.splat];
      });
      router.add("/multi/:name/*", function(params) {
        return ["multi", params.name, params.splat];
      });
      router.add("/reverse-multi/*/:name", function(params) {
        return ["reverse-multi", params.splat, params.name];
      });
      router.add("/index.html", function(params) {
        return "ok";
      });
      it("with single named parameter", function() {
        return eq(router.exec("/one-name/mikko").result, ['one-name', 'mikko']);
      });
      it("with two named parameters", function() {
        return eq(router.exec("/two-name/mikko/apo").result, ['two-name', 'mikko', "apo"]);
      });
      it("with two parameters with same name", function() {
        return eq(router.exec("/double-name/mikko/apo").result, ['double-name', ['mikko', "apo"]]);
      });
      it("with wildcard", function() {
        eq(router.exec("/foo/mikko").result, ['foo', 'mikko']);
        return eq(router.exec("/foo/mikko/bar").result, ['foo', 'mikko/bar']);
      });
      it("with named parameter and wildcard", function() {
        eq(router.exec("/multi/mikko/bar").result, ['multi', 'mikko', 'bar']);
        return eq(router.exec("/multi/mikko/foo/bar").result, ['multi', 'mikko', 'foo/bar']);
      });
      it("with wildcard and named parameter", function() {
        eq(router.exec("/reverse-multi/bar/mikko").result, ['reverse-multi', 'bar', 'mikko']);
        return eq(router.exec("/reverse-multi/foo/bar/mikko").result, ['reverse-multi', 'foo/bar', 'mikko']);
      });
      it("with undefined should return undefined", function() {
        return eq(router.exec("/i"), void 0);
      });
      it("with urls containg dot", function() {
        return eq(router.exec("/index.html").result, "ok");
      });
      return it("and escape regex dot", function() {
        return eq(router.exec("/indexahtml"), void 0);
      });
    });
    describe("should provide listeners", function() {
      var router;
      router = KiRouter.router();
      router.disableUrlUpdate = true;
      it("for execution results", function() {
        var results;
        results = [];
        router.add("/foo", function(params) {
          return "cool!";
        });
        router.addPostExecutionListener(function(matched, previous) {
          return results.push(matched.result);
        });
        router.exec("/foo");
        return eq(["cool!"], results);
      });
      return it("for listening to exceptions", function() {
        var errors;
        errors = [];
        router.add("/exception", function(params) {
          throw new Error("uups!");
        });
        router.addExceptionListener(function(matched, previous) {
          return errors.push(matched.error.message);
        });
        try {
          router.exec("/exception");
          throw new Error("should have raised an exception!");
        } catch (_error) {

        }
        return eq(["uups!"], errors);
      });
    });
    return describe("browser integration", function() {
      beforeEach(function(done) {
        window.open("about:blank", "test_window");
        return setTimeout(done, 10);
      });
      it("should render correct view", zhain().window_open("/", function(w) {
        return pState(w, "/", "0", "No path!", false);
      }).window_open("/index.html", function(w) {
        return pState(w, "/index.html", "1", "/index.html", false);
      }).test());
      it("should handle click to /foo without reloading page", zhain().window_open("/", function(w) {
        return pState(w, "/", "0", "No path!", false);
      }).click("#pageSame", function(w) {
        return pState(w, "/", "0", "No path!", true);
      }).click("#link_foo", function(w) {
        return pState(w, "/foo", "1", "/foo", true);
      }).click("#link_index", function(w) {
        return pState(w, "/index.html", "2", "/index.html", true);
      }).click("#link_foo", function(w) {
        return pState(w, "/foo", "3", "/foo", true);
      }).back(function(w) {
        return pState(w, "/index.html", "4", "/index.html", true);
      }).test());
      it("should handle direct link to /#!/foo", zhain().window_open("/#!/foo", function(w) {
        return pState(w, "/#!/foo", "1", "/foo", false);
      }).click("#pageSame", function(w) {
        return pState(w, "/#!/foo", "1", "/foo", true);
      }).click("#link_foo", function(w) {
        return pState(w, "/foo", "2", "/foo", true);
      }).test());
      return it("should handle direct link to /#/foo", zhain().window_open("/#/foo", function(w) {
        return pState(w, "/#/foo", "1", "/foo", false);
      }).click("#pageSame", function(w) {
        return pState(w, "/#/foo", "1", "/foo", true);
      }).click("#link_foo", function(w) {
        return pState(w, "/foo", "2", "/foo", true);
      }).test());
    });
  });

}).call(this);
