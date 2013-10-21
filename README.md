# Sinatra route syntax + pushState/hashbang support + plain urls

Sinatra uses a powerful url based routing syntax to identify different views in the application. Javascript
single page apps can benefit from the same by using walter-js.

# How to use it?

Check the [demo](demo.html) :)

First you'll need a HTML fragment that contains regular a links:

    <p>
        Main page: <a href="/repository">Repository</a>
        Component: <a href="/repository/component/ki/demo">ki/demo</a>
    </p>

Then you need to include walter.js

    <script type="text/javascript" src="walter.js"></script>

Routing configuration defines how different urls are rendered

    function initRouter() {
        router = Walter.router();
        router.add("/repository/component/*", function (params) { show_component( params.splat ) } );
        router.add("/repository", function (params) { show_components( ) } );
        router.add("/say/*/to/:name", function (params) { say_hello( params.splat, params.name ) } );
        router.fallbackRoute = function (url) { alert("Unknown route: " + url) };
        router.hashBaseUrl = "/repository";
        router.initRouting();
    }
    initRouter();

router.add(urlPattern, function) defines url pattern and a function that is executed if the specific url is used.
Routes are matched in the order they are defined. The first route that matches the url is invoked. Route patterns may
include named parameters or wildcard (*) parameters. Named parameters are accessible from the params with _params.name_
and wildcard parameters are available from _params.splat_. If the url pattern contains multiple instances of named
parameter, _params.name_ will be a list.

router.initRouting() sets up the routing on the browser:

* it switches browser url between pushState and hashBang if needed
* it registers a click handler for A tags
* it registers a listener to handle url back & forward buttons: by using onpopstate or onhashchange or onhashchange emulation
* it renders the view based on the current url

# Features

* Bookmarkable urls are easy to implement
* Supports history.pushState and hashbang (#!). Is able to convert urls between those two formats if urls are copied between browsers.
* Provides a centralized control structure for the application
* Removes the need to bind view change listeners in javascript
* Plain HTML with regular a href links
* Gracefully degrading web app (pushState -> hashBang -> no javascript)
* Supports ctrl, shift, alt and meta keys so users can open new tabs and windows easily
* Supports A tag's target attribute: ___blank, ___self, ___parent, ___top, window name
* Attaches listeners to document level, does not interfere with events handled by application
