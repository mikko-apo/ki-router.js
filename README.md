# Sinatra route syntax + pushState and hashbang support + plain urls

ki-router.js is a [Sinatra](http://www.sinatrarb.com/) inspired javascript router with browser support.
When a user opens a page or clicks a link, ki-router.js parses the associated url and tries to find a a matching url
pattern. First matching url is parsed for parameters and ki-router.js calls a function with the parameters.

```javascript
router = KiRouter.router();
router.add("/say/*/to/:name", function (params) { say_hello( params.splat, params.name ) } );
router.exec("/say/Hello 123/456/to/world") // say_hello is called with {name: "world", splat: "Hello 123/456"}
```

# Why should you use it?

ki-router.js gives you:
* Bookmarkable and clean REST like urls: /book/123
* Url parameter parsing: params.id => "123"
* No dependencies on other javascript libraries
* Centralized and clear control structure for the application

ki-router.js makes it easy to create a modern javascript app in a clean way:
* Use regular links in HTML. This leads to cleaner javascript and there is no more need to bind view change listeners in javascript
* Browser support: Chrome, Firefox, Safari, IE10/9/8, Opera
* Gracefully degrading web app with support for even older browsers: pushstate -> hashbang -> javascript but no pushstate/hashbang -> no javascript

All you need to do to is:
* Include ki-router.js
* Use plain HTML with regular href links
* Configure router routes and start the router

Additional technical features include:
* Support for browser keyboard shortcuts. Users can open new tabs and windows easily: ctrl, shift, alt and meta keys
* Support for A tag's target attribute: ___blank, ___self, ___parent, ___top, window name
* Simple integration with other javascript frameworks. Attaches listeners to document level, does not interfere with events handled by application's javascript

Check out the demo at http://ki-router.ki-flow.org/

# Install

* Npm: npm install --save ki-router
* Bower: bower install --save ki-router
* Coffeescript (original source): [src/ki-router.coffee](https://raw.github.com/mikko-apo/ki-router.js/master/src/ki-router.coffee)
* Javascript: [dist/ki-router.js](https://raw.github.com/mikko-apo/ki-router.js/master/dist/ki-router.js) [dist/ki-router.min.js](https://raw.github.com/mikko-apo/ki-router.js/master/dist/ki-router.min.js)

# How to use it?

## HTML

First you'll need a HTML fragment that contains regular a links:

```html
<p>
    Main page: <a href="/repository">Repository</a>
    Component: <a href="/repository/component/ki/demo">ki/demo</a>
</p>
```

Then you need to include ki-router.js

```html
<script type="text/javascript" src="ki-router.js"></script>
```

## Router configuration

Routing configuration defines how different urls are handled:

```javascript
router = KiRouter.router();
router.add("/repository/component/*", function (params) { show_component( params.splat ) } );
router.add("/repository", function (params) { show_components( ) } );
router.add("/say/*/to/:name", function (params) { say_hello( params.splat, params.name ) } );
router.fallbackRoute = function (url) { alert("Unknown route: " + url) };
router.hashBaseUrl = "/repository";
router.paramVerifier = function (s) { /^[a-z0-9\/]+$/i.test(s) };
// router.debug = true
router.transparentRouting();
```

`router.add(urlPattern, function, metadata)` defines url pattern and a function that is executed if the specific url is used. It is also possible to attach a metadata object to the route that can contain useful information for intercepting the triggered route. This can be for example analytics information.
Routes are matched in the order they are defined. The first route that matches the url is invoked. Route patterns may
include named parameters or wildcard (*) parameters. Named parameters are accessible from the params with _params.name_
and wildcard parameters are available from _params.splat_. If the url pattern contains multiple instances of named
parameter, _params.name_ will be a list.

`router.fallbackRoute` function is executed if there is no matching route. It can be used to render a default page or log an error.

`router.hashBaseUrl` is used if user accesses the application with a browser that doesn't support history-API, but supports onhashchange.
Browser is redirected to that address and application pages are rendered using the hashbang.

`router.paramVerifier` is a function that can be used to sanitize all the parameters. This is useful if any of the parameters
is used to render HTML. Attacker may otherwise encode HTML in the url that is rendered to the page.

`router.transparentRouting()` attaches listeners for clicks, popstate and hashchange events and renders the initial view based on browser url.

# Different ways to use ki-router.js

## Hashbang mode

This is the regular single page app mode. The app uses hash (#/user/1) or hashbang (#!/user/1) urls.
Hashbang mode is useful if you prefer hash urls or want to serve your application from a single url or file.

Additional things to consider:
* Links in HTML document can be in either plain format or prefixed with "#!". Both of these will work: "/path/123" and "#!/path/123"
* Currently there is no support for browsers without "onhashchange"
* Needs javascript-support from browser because server does not get access to anchor

```javascript
router.hashbangRouting()
```

When user clicks links in hashbang mode, ki-router.js generates hash (#) links. Hashbang urls are enabled with following:

```javascript
router.serverSupportsEscapedFragment = true
```

More information: https://developers.google.com/webmasters/ajax-crawling/docs/getting-started

## Transparent mode

Transparent mode uses HTML5 History API to simulate a regular link based web app.
If the browser doesn't support the History Api, it switches to using hashbangs.

This mode is useful if you want to optimize network traffic. It also provides a gracefully
degrading web app: application manages different views with History API or hashbangs. If there
is no javascript support, links are handled by the backend server.

Additional things to consider:

* history.pushState and hashbang (# or #!) support. ki-route.js is able to convert urls between those two formats if urls are copied between browsers.
* Gracefully degrading web app (pushState -> hashBang -> javascript but no pushState/hashBang -> no javascript)
* Search engine support is tricky: Servers needs to return correct content for the url and support _escaped_fragments_ urls also
* If the browser doesn't support javascript all links will lead back to server and server needs to render the correct page
* Backend server needs to have a wildcard url that returns the same page for all possible links to enable bookmarkable urls or refreshes

```ruby
get '/*' do
  erb :repository_page
end
```

## HistoryApi mode

This is the best mode if you want nice plain urls and none of that hashbang mess. In HistoryApi mode ki-router.js intercepts link clicks
only if the browser supports the History API. With older browsers (IE9/8) without History API support each link click forces browser to get a new page
and ki-router.js renders the correct view.

Additional things to consider:

* Backend server needs be configured so that it returns a page for all possible urls. The page can have same content if you use ki-router.js to render the correct view.
* Search engine support is still tricky, but a bit easier: Server needs to return correct content for the url

```javascript
router.historyApiRouting()
```

## Without browser

ki-router.js is good for parsing URL like strings and it works without a browser.
You can configure any number of urls and functions, like this:

```javascript
router = KiRouter.router();
router.add("/say/*/to/:name", function (params) { say_hello( params.splat, params.name ) } );
router.exec("/say/Hello 123/456/to/world")
```

# Extra api

## Route metadata

It's possible to add metadata information to routes. This metadata is available for postExecutionListener and
it can be used for for example Google Analytics

```javascript
router.add("/repository", function (params) { show_components( ) } );
router.add("/repository/component/*", function (params) { show_component( params.splat ) }, {ga: "Component"} );
```

## Routing events

### Post execution

It is possible to listen for triggered routes by registering an listener function that is valled each time the route has been triggered.

```javascript
router.addPostExecutionListener(function(matched, previous) {
    if( matched.metadata && matched.metadata.ga ) {
        addAnalyticsEvent(matched.metadata.ga, previous.metadata.ga);
    }
})
```

Listener callback gets two parameters that are the route information of the currently triggered route and the previous route.

Matched and previous are hashes, that contain following values:

```javascript
{
    path: "/repository/component/abc",
    params: {"splat": "abc"},
    metadata: {"ga": "Component"},
    result: ...,
    urlPattern: "/repository/component/*/",
    route: ...,
    fn: ...
}
```

### Exceptions

Ki-router provides a listener mechanism to listen to exceptions. The exception is available from matched.error:

```javascript
router.addExceptionListener(function(matched, previous) {
    console.log(matched.error);
})
```

# Development

To run automated tests run following:

```bash
npm install
./grunt connect:http8090 build watch
```

Connect your browser to [http://localhost:8090/spec/test.html](http://localhost:8080/spec/test.html) to run tests.

You can also connect to ports 80 (http), 443 (https), 8090 (http) and 8443 (https)

```bash
./grunt connect build watch
```

# Release History
* 2015-01-12 1.1.17 Renamed npm package to ki-router, no changes to 1.1.16
* 2015-01-11 1.1.16 Fixed warning message for Chrome: 'Attr.nodeValue' is deprecated. Please use 'value' instead. (thanks santtul) https://github.com/mikko-apo/ki-router.js/issues/3
* 2015-01-11 1.1.15 Defaults to redirecting to #/ instead of #!/. Handles both #/ and #!/ links. ki-router published to https://www.npmjs.com/ also.
* 2015-01-09 1.1.14 Firefox 34 returns window.location.username as "" for unauthenticated users, fixed link comparison handling
* 2014-03-27 1.1.13 Fixed attachLocationChangeListener popstate to work when ki-router.js is used without clicksupport (thanks antris)
* 2014-03-18 1.1.12 Removed harmful try catch that hid errors (thanks raimohanska). Testing reports if popups are blocked (thanks tkurki)
* 2014-02-24 1.1.11 Fix for Chrome and Safari popstate on page load, popstate is ignored until page is rendered once through click
* 2014-02-02 1.1.10 IE6 support, addExceptionListener
* 2014-01-28 1.1.9 IE8 support and historyApiRouting
* 2014-01-17 1.1.8 targetHostSame fix protocols needed a ":"
* 2014-01-17 1.1.7 Fixed targetHostSame to handle that IE9 sets target port to "443"
* 2014-01-17 1.1.6 Fixed targetHostSame check to work with IE9 and https links
* 2014-01-17 1.1.5 Debug log uses JSON.stringify to support browsers
* 2014-01-07 1.1.4 Firefox 26 actually sets target.username to empty string
* 2013-12-30 1.1.3 Fix for Firefox 26 setting window.location.username to undefined instead of empty string
* 2013-12-16 1.1.2 Add support for listening route triggering. It's also possible to define metadata for routes (thanks jliuhtonen)
* 2013-11-20 1.1.1 Added KiRouter.version that is updated automatically for releases
* 2013-11-20 1.1.0 renderInitialView does not change url format automatically anymore
* 2013-11-07 1.0.0 Supports now two modes "transparent" and "hashbang"
