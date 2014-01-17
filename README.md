# Sinatra route syntax + pushState/hashbang support + plain urls

Sinatra defined a powerful url routing syntax that is used to identify different views in the application and the
parameters used by the view. Javascript single page apps can benefit from the same by using ki-router.js.

# Why should you use it?

ki-router.js makes it relative easy to implement a modern single page app that supports clean REST-like bookmarkable
urls. It supports two kinds of single page app modes:

* transparent
* hashbang

To use it all you need to do to is:

* Use plain HTML with regular a href links
* Include ki-router.js
* Configure router routes
* (For transparent mode you need to configure backend server to return the same page for all possible urls)

In return you get:

* Bookmarkable and clean REST like urls
* Url parameter parsing
* Centralized and clear control structure for the application
* Cleaner javascript, there is no more need to bind view change listeners in javascript

Additional technical features include:

* Support for browser keyboard shortcuts so users can open new tabs and windows easily: ctrl, shift, alt and meta keys
* Support for A tag's target attribute: ___blank, ___self, ___parent, ___top, window name
* Simple integration with other javascript frameworks. Attaches listeners to document level, does not interfere with events handled by application's javascript
* No dependencies on other javascript libraries

# Two modes of operation

## Transparent mode

Transparent mode uses HTML5 History API to simulate a regular link based web app. It intercepts clicks to A tags and
if it knows the url it renders the correct view and changes the browser url.
If the browser doesn't support the History Api, it switches to using hashbangs.
If you don't like hashbangs in the url (except as a fallback), use this mode.

Additional things to consider:

* history.pushState and hashbang (#!) support. ki-route.js is able to convert urls between those two formats if urls are copied between browsers.
* Gracefully degrading web app (pushState -> hashBang -> javascript but no pushState/hashBang -> no javascript)
* If the browser doesn't support javascript all links will lead back to server and server needs to render the correct page
* Backend server needs to have a wildcard url that returns the same page for all possible links

## Hashbang mode

Hashbang mode is useful if you either prefer hashbang urls or want to serve your application from single url

Additional things to consider:
* Links in HTML document can be in either plain format or prefixed with "#!". Both of these will work: "/path/123" and "#!/path/123"
* There is no fallback for browsers without "onhashchange" support or browsers without javascript support

# How to use it?

## HTML

First you'll need a HTML fragment that contains regular a links:

    <p>
        Main page: <a href="/repository">Repository</a>
        Component: <a href="/repository/component/ki/demo">ki/demo</a>
    </p>

Then you need to include ki-router.js

    <script type="text/javascript" src="ki-router.js"></script>

## Router configuration

Routing configuration defines how different urls are rendered

    router = KiRouter.router();
    router.add("/repository/component/*", function (params) { show_component( params.splat ) } );
    router.add("/repository", function (params) { show_components( ) } );
    router.add("/say/*/to/:name", function (params) { say_hello( params.splat, params.name ) } );
    router.fallbackRoute = function (url) { alert("Unknown route: " + url) };
    router.hashBaseUrl = "/repository";
    router.paramVerifier = function (s) { /^[a-z0-9\/]+$/i.test(s) };
    // router.debug = true
    router.transparentRouting();

router.add(urlPattern, function, metadata) defines url pattern and a function that is executed if the specific url is used. It is also possible to attach a metadata object to the route that can contain useful information for intercepting the triggered route. This can be for example analytics information.
Routes are matched in the order they are defined. The first route that matches the url is invoked. Route patterns may
include named parameters or wildcard (*) parameters. Named parameters are accessible from the params with _params.name_
and wildcard parameters are available from _params.splat_. If the url pattern contains multiple instances of named
parameter, _params.name_ will be a list.

router.fallbackRoute function is executed if there is no matching route. It can be used to render a default page or log an error.

router.hashBaseUrl is used if user accesses the application with a browser that doesn't support history-API, but supports onhashchange.
Browser is redirected to that address and application pages are rendered using the hashbang.

router.paramVerifier is a function that can be used to sanitize all the parameters. This is useful if any of the parameters
is used to render HTML. Attacker may otherwise encode HTML in the url that is rendered to the page.

### Transparent routing

router.transparentRouting() sets up the routing on the browser:

* it registers a click handler for A tags that handles all clicks to known links
* it registers a listener to handle url back & forward buttons: by using onpopstate or onhashchange
* it renders the view based on the current url

Note:

To enable bookmarkable urls, you need to configure the backend server with a wildcard url that returns the main page
for all possible urls. That page should load the router configuration and then router.transparentRouting() renders the correct page.

    get '/*' do
      erb :repository_page
    end

### Hashbang routing

    router.hashbangRouting()

## Route metadata

It's possible to add metadata information to routes. This metadata is available for postExecutionListener and
it can be used for for example Google Analytics

    router.add("/repository", function (params) { show_components( ) } );
    router.add("/repository/component/*", function (params) { show_component( params.splat ) }, {ga: "Component"} );

## Routing events

It is possible to listen for triggered routes by registering an listener function that is valled each time the route has been triggered.

    router.addPostExecutionListener(function(matched, previous) {
        if( matched.metadata && matched.metadata.ga ) {
            addAnalyticsEvent(matched.metadata.ga, previous.metadata.ga);
        }
    })

Listener callback gets two parameters that are the route information of the currently triggered route and the previous route.

Matched and previous are hashes, that contain following values:

    {
        path: "/repository/component/abc",
        params: {"splat": "abc"},
        metadata: {"ga": "Component"},
        result: ...,
        urlPattern: "/repository/component/*/",
        route: ...,
        fn: ...
    }

# Install

* Bower: bower install --save ki-router
* Coffeescript (original source): [src/ki-router.coffee](https://raw.github.com/mikko-apo/ki-router.js/master/src/ki-router.coffee)
* Javascript: [dist/ki-router.js](https://raw.github.com/mikko-apo/ki-router.js/master/dist/ki-router.js)

# Release History
* 2014-01-17 1.1.6 Fixed targetHostSame check to work with IE9 and https links
* 2014-01-17 1.1.5 Debug log uses JSON.stringify to support browsers
* 2014-01-07 1.1.4 Firefox 26 actually sets target.username to empty string
* 2013-12-30 1.1.3 Fix for Firefox 26 setting window.location.username to undefined instead of empty string
* 2013-12-16 1.1.2 Add support for listening route triggering. It's also possible to define metadata for routes
* 2013-11-20 1.1.1 Added KiRouter.version that is updated automatically for releases
* 2013-11-20 1.1.0 renderInitialView does not change url format automatically anymore
* 2013-11-07 1.0.0 Supports now two modes "transparent" and "hashbang"
