# Sinatra route syntax + pushState/hashbang support + plain urls

Sinatra uses a powerful url based routing syntax to identify different views in the application. Javascript
single page apps can benefit from the same by using walter-js.

# How to use it?

First you'll need a HTML fragment that contains regular a links:

    <p>
        Main page: <a href="/repository">Repository</a>
        Component: <a href="/repository/component/ki/demo">ki/demo</a>
    </p>

Then you need to include walter.js

    <script type="text/javascript" src="ki-router.js"></script>

Routing configuration defines how different urls are rendered

    router = KiRouter.router();
    router.add("/repository/component/*", function (params) { show_component( params.splat ) } );
    router.add("/repository", function (params) { show_components( ) } );
    router.add("/say/*/to/:name", function (params) { say_hello( params.splat, params.name ) } );
    router.fallbackRoute = function (url) { alert("Unknown route: " + url) };
    router.hashBaseUrl = "/repository";
    router.paramVerifier = function (s) { /^[a-z0-9\/]+$/i.test(s) }
    // router.debug = true
    router.initRouting();

router.add(urlPattern, function) defines url pattern and a function that is executed if the specific url is used.
Routes are matched in the order they are defined. The first route that matches the url is invoked. Route patterns may
include named parameters or wildcard (*) parameters. Named parameters are accessible from the params with _params.name_
and wildcard parameters are available from _params.splat_. If the url pattern contains multiple instances of named
parameter, _params.name_ will be a list.

router.fallbackRoute function is executed if there is no matching route. It can be used to render a default page or log an error.

router.hashBaseUrl is used if user accesses the application with a browser that doesn't support history-API, but supports onhashchange.
Browser is redirected to that address and application pages are rendered using the hashbang.

router.paramVerifier is a function that can be used to sanitize all the parameters. This is useful if any of the parameters
is used to render HTML. Attacker may otherwise encode HTML in the url that is rendered to the page.

router.initRouting() sets up the routing on the browser:

* it switches browser url between pushState and hashBang if needed
* it registers a click handler for A tags that handles all clicks to known links
* it registers a listener to handle url back & forward buttons: by using onpopstate or onhashchange
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
