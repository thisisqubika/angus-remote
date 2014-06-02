# angus-remote

With angus remote you can easy interact with services built
using [angus] (https://github.com/Moove-it/angus) or services that
use [angus-sdoc] (https://github.com/Moove-it/angus-sdoc) to expose its documentation.

## Features

* Easy to use.
* Uses persistent connections to improve performance.
* Comes with [angus-authentication] (https://github.com/Moove-it/angus-authentication) support.

## Installation

Add this line to your application's Gemfile:

    gem 'angus-remote'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install angus-remote

## Usage

Once you have everything installed you just need to provide the information where to find the
service documentation and api paths, there are 2 ways of doing so:

### First method

The easiest way is to provide both paths when doing a service lookup:

```ruby
remote_service = Angus::Remote::ServiceDirectory.lookup({ code_name: 'demo'                               # Required
                                                          version: '0.2',                                 # Defaults to 0.1
                                                          api_url: 'http://localhost:9292/demo/api/0.2/', # Required
                                                          doc_url: 'http://localhost:9292/demo/doc/0.2/'  # Required })
```

### Second method

The other way is less straight forward but you end up with a more organized set of services:
```ruby
remote_service = Angus::Remote::ServiceDirectory.lookup('demo', '0.1')
```

Then create a yml called services.yml inside the config folder config, you should end up with: "#PROJECT_ROOT/config/services.yml"
in that file you should put:
```yml
demo:
  v0.1:
    api_url: http://localhost:9292/demo/api/0.1/
    doc_url: http://localhost:9292/demo/doc/0.1/
```

Ok now you a remote_service object, to use it just call methods exposed by it, you can check them out
by reading the service doc url.

For instance if your remote service points a unmodified angus demo project and you want to
get a list of users you can:

```yml
remote_service.get_users.users
```
That will get you an array of user objects that respond to the methods specified in
the api documentation.

### Passing parameters

To pass parameters to the remote service you just need to pass them when invoking the remote method:

```ruby
remote_service.find_user({ name: 'John' })
```

Depending on the HTTP method of the "find_user" operation, the parameters are either encoded in
the url (GET) or sent as form data in the request body (POST, PUT).

You can also send the parameters as a json in the request body, like this:

```ruby
remote_service.create_user(true, { name: 'John', last_name: 'Doe' })
```

## Using angus-authentication
Soon to come

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes and tests (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request