# OAuther

[![Build Status](https://travis-ci.org/lexmag/oauther.svg)](https://travis-ci.org/lexmag/oauther)
[![Hex Version](https://img.shields.io/hexpm/v/oauther.svg)](https://hex.pm/packages/oauther)

Library to authenticate with [OAuth 1.0](http://tools.ietf.org/html/rfc5849) protocol.

## Installation

Add OAuther as a dependency to your `mix.exs` file:

```elixir
defp deps do
  [{:oauther, "~> 1.1"}]
end
```

After you are done, run `mix deps.get` in your shell to fetch the dependencies.

## Usage

Example below shows the use of [hackney HTTP client](https://github.com/benoitc/hackney)
for interacting with Twitter API.
Protocol parameters are transmitted using the HTTP "Authorization" header field.

```elixir
creds = OAuther.credentials(consumer_key: "dpf43f3p2l4k3l03", consumer_secret: "kd94hf93k423kf44", token: "nnch734d00sl2jdk", token_secret: "pfkkdhi9sl3r4s00")
# => %OAuther.Credentials{consumer_key: "dpf43f3p2l4k3l03",
# consumer_secret: "kd94hf93k423kf44", method: :hmac_sha1,
# token: "nnch734d00sl2jdk", token_secret: "pfkkdhi9sl3r4s00"}
params = OAuther.sign("post", "https://api.twitter.com/1.1/statuses/lookup.json", [{"id", 485086311205048320}], creds)
# => [{"oauth_signature", "10ZSs6eeWP+IfzElF5xFX/wsqnY="},
# {"oauth_consumer_key", "dpf43f3p2l4k3l03"},
# {"oauth_nonce", "M0vwJncX7T2GQwGXM4zFEa1mvL9RReLtkwwcBvlxG0A="},
# {"oauth_signature_method", "HMAC-SHA1"}, {"oauth_timestamp", 1404500030},
# {"oauth_version", "1.0"}, {"oauth_token", "nnch734d00sl2jdk"},
# {"id", 485086311205048320}]
{header, req_params} = OAuther.header(params)
# => {{"Authorization",
# "OAuth oauth_signature=\"10ZSs6eeWP%2BIfzElF5xFX%2FwsqnY%3D\", oauth_consumer_key=\"dpf43f3p2l4k3l03\", oauth_nonce=\"M0vwJncX7T2GQwGXM4zFEa1mvL9RReLtkwwcBvlxG0A%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1404500030\", oauth_version=\"1.0\", oauth_token=\"nnch734d00sl2jdk\""},
# [{"id", 485086311205048320}]}
:hackney.post("https://api.twitter.com/1.1/statuses/lookup.json", [header], {:form, req_params})
# => {:ok, 200, [...], #Reference<0.0.0.837>}
```
----

For OAuth1.0a(Twitter Authentication)

### (Step1) Twitter Application Management Settings
Visit and setting [Twitter Application Management](https://apps.twitter.com/).

### (Step2) Get access_token for OAuth  
**Callback url is must set your apps url.(There is sample Apps url in this step)**
```elixir
creds = OAuther.credentials(consumer_key: "your consumer key", consumer_secret: "your consumer secret", token: "your access token", token_secret: "your access token secret", callback: "http://oauth-verifier-bonblog.a3c1.starter-us-west-1.openshiftapps.com/callback")
# => %OAuther.Credentials{callback: nil, consumer_key: "XXXX",
# consumer_secret: "YYYY",
# method: :hmac_sha1,
# token: "ZZZZ",
# token_secret: "WWWW", verifier: nil, callback: "http://..."}
url = "https://api.twitter.com/oauth/request_token"
# => "https://api.twitter.com/oauth/request_token"
params = OAuther.sign("post", url, [], creds)
# => [{"oauth_signature", "AAAA"},
# {"oauth_consumer_key", "XXXX"},
# {"oauth_nonce", "BBBB"},
# {"oauth_signature_method", "HMAC-SHA1"}, {"oauth_timestamp", 0000},
# {"oauth_version", "1.0"}, {"oauth_callback", nil}, {"oauth_verifier", nil},
# {"oauth_token", "ZZZZ"}]
{req_header, req_params} = OAuther.header(params)
# => {{"Authorization",
# "OAuth oauth_signature=\"AAAA\", oauth_consumer_key=\"XXXX\", oauth_nonce=\"BBBB\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"0000\", oauth_version=\"1.0\", oauth_token=\"ZZZZ\""},
# []}
{:ok, status, reqHeaders, client} = :hackney.post(url, [req_header], [])
# => {:ok, 200, [...], #Reference<0.0.0.837>}
{:ok, oauth_token} = :hackney.body(client)
# => {:ok,
# "oauth_token=CCCC&oauth_callback_confirmed=true"}
oauth_token
"oauth_token=CCCC&oauth_callback_confirmed=true"
```

### (Step3) Get params of verifier

* Open Your Web Browser(Firefox,Chrome,Edge and so on)
* Enter URL : "https://api.twitter.com/oauth/authorize?oauth_token=CCCC&oauth_callback_confirmed=true"  
Set oauth_token obtained in the **step2** as the query parameter.
If you can get error page that 'Invalid token', you try get oauth_token again.

```elixir
{:ok, status, reqHeaders, client} = :hackney.post(url, [header], {:form, req_params})
{:ok, oauth_token} = :hackney.body(client)
# => {:ok,
# "oauth_token=DDDD&oauth_callback_confirmed=true"}
```

So, you can get verifier token on your web browser.

### (Step4) You can use Twitter API

e.g. User Search API that requires authentication the OAuth1.0a

```elixir
creds = OAuther.credentials(consumer_key: "your consumer key", consumer_secret: "your consumer secret", token: "your access token", token_secret: "your access token secret", verifier: "Verifier obtained in step 3")
# => %OAuther.Credentials{callback: nil, consumer_key: "XXXX",
# consumer_secret: "YYYY",
# ...
params = OAuther.sign("get", "https://api.twitter.com/1.1/users/search.json?q=Elixir", [], creds)
# => [{"oauth_signature", "AAAA"},
# {"oauth_consumer_key", "XXXX"},
# ...
{req_header, req_params} = OAuther.header(params)
# => {{"Authorization",
# "OAuth oauth_signature=\"AAAA\",
# ...
{:ok, status, reqHeaders, client} = :hackney.get("https://api.twitter.com/1.1/users/search.json?q=Elixir", [req_header], [])
# {:ok, 200,
# [{"cache-control",
# ...
{:ok, body} = :hackney.body(client)
# {:ok,
# "[{\"id\":1867121,\"id_str\":\"1867121\",\"name\ ....
```


## License

This software is licensed under [the ISC license](LICENSE).
