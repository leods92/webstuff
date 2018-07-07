---
layout: post
title: "XHR's responseURL polyfill?"
date: 2018-07-07T13:06:00+02:00
---

It all started at work.

While developing a new feature, we realized we couldn't use [Uppy](https://github.com/transloadit/uppy) as an up-loader on Internet Explorer 11.
The problem we had was caused by Uppy's [S3 plug-in](https://uppy.io/docs/aws-s3/) which relies on `XmlHttpResponse`'s `responseURL` which is not available in older browsers.

# `responseURL`

This `XmlHttpResponse` property was introduced in the XHR spec in Feb 2014 by [this commit](https://github.com/whatwg/xhr/commit/0c9670185b79c255211881e086e05e7a99e65f06) because of [this bug](https://www.w3.org/Bugs/Public/show_bug.cgi?id=15417).

Its value is a string representation of the response URL.

> Isn't it the same as the request URL?

No.

The URLs you request might be redirected to other ones until you finally get a response. The last URL in a redirection-chain is the response URL.

In case there's no redirection, yes, the request URL is the same as the response URL.

# Solving the problem

## Reading the `Location` header

I asked myself:

> How about getting the URL from the `Location` HTTP header?

The problem is that that header is never visible to `XmlHttpRequest` instances.

From [the spec](https://dvcs.w3.org/hg/xhr/raw-file/tip/Overview.html#infrastructure-for-the-send%28%29-method):

> If the source origin and the origin of request URL are same origin **transparently follow the redirect** while observing the same-origin request event rules.

That means that if a redirect happens, only the information from the last URL in the redirection-chain will be available.
If we could prevent the redirections from happening transparently, we could read and store the most recent `Location` value and then handle the final redirection ourselves.

Unfortunately, that is not possible.


## Reading a custom HTTP header

This is [the way](https://github.com/github/fetch/blob/da07fa1dde1b6db238ef5567c1096dd9873e3ebf/README.md#obtaining-the-response-url) GitHub's fetch polyfill tackles the problem.

In order to work, their solution requires control over the HTTP server and the sending of a `X-Request-URL` header.

In our case, we're hitting an S3 server we don't control; adding custom headers is probably not possible.

## Falling back to the request URL

To implement this in a "clean" way, I'd first detect if there were redirections.

If there were no redirections, I'd use the request URL as the response URL.

Otherwise, I'd throw an error because in this case it'd be impossible to know what the response URL is.

Detecting redirections is not possible with `XmlHttpRequest` because there's no property, method or (standard) header that determines whether a redirection happened.

Getting the request URL is also not so simple.
While looking at MDN's [XMLHTTPRequest documentation](https://developer.mozilla.org/en-US/docs/Web/API/XMLHTTPRequest#Constructor) and [Chromium's source code](https://github.com/chromium/chromium/blob/master/third_party/blink/renderer/core/xmlhttprequest/xml_http_request.cc), I noticed that there's no public property or method which one can get the request URL from.

## How I moved forward

I couldn't come up with a clean server-less fix for this issue.

The way I decided to move forward with was to fall back to the request URL when the `responseURL` property is undefined.
And I think that's good enough.

Drawbacks to consider:

1. If there's a redirection and the code relies on the `responseURL`, wrong things may happen; in this case, the response URL is not the same as the request URL.
2. In order to retrieve the request URL, the URL must be saved somewhere accessible beforehand.

I still think it's an appropriate solution for our case because:

1. I cannot think of a situation in which S3 would redirect upload requests.
2. IE11 support is currently inexistent so anything is better than nothing.

I've opened a PR fixing Uppy's S3 plug-in's issue.

Now I'm hoping that the maintainers accept it :P

# Polyfill?

While researching about this issue, I couldn't find any polyfill.
Because of that, I thought of writing one myself but I decided not to.

In my opinion, the solution I decided to move forward with would not be suitable for a polyfill; simply because it wouldn't be 100% compliant with `responseURL`'s spec.

I even imagined developers wasting their time with "weird issues" because of it.

So I decided to write this post instead and share as much information as I can with fellow developers. 🤗


# Additional links

- [Chromium's `responseURL` tests](https://github.com/chromium/chromium/blob/master/third_party/WebKit/LayoutTests/http/tests/xmlhttprequest/responseURL.html).
- [Stack Overflow discussion](https://stackoverflow.com/questions/8056277/how-to-get-response-url-in-xmlhttprequest)
- [Fetch polyfill issue](https://github.com/github/fetch/issues/443)
- [`responseURL` compatibility list](https://developer.mozilla.org/de/docs/Web/API/XMLHttpRequest/responseURL)
