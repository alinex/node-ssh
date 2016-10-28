Alinex SSH Connections: Readme
=================================================

[![GitHub watchers](
  https://img.shields.io/github/watchers/alinex/node-ssh.svg?style=social&label=Watch&maxAge=2592000)](
  https://github.com/alinex/node-ssh/subscription)
<!-- {.hidden-small} -->
[![GitHub stars](
  https://img.shields.io/github/stars/alinex/node-ssh.svg?style=social&label=Star&maxAge=2592000)](
  https://github.com/alinex/node-ssh)
[![GitHub forks](
  https://img.shields.io/github/forks/alinex/node-ssh.svg?style=social&label=Fork&maxAge=2592000)](
  https://github.com/alinex/node-ssh)
<!-- {.hidden-small} -->
<!-- {p:.right} -->

[![npm package](
  https://img.shields.io/npm/v/alinex-ssh.svg?maxAge=2592000&label=latest%20version)](
  https://www.npmjs.com/package/alinex-ssh)
[![latest version](
  https://img.shields.io/npm/l/alinex-ssh.svg?maxAge=2592000)](
  #license)
<!-- {.hidden-small} -->
[![Travis status](
  https://img.shields.io/travis/alinex/node-ssh.svg?maxAge=2592000&label=develop)](
  https://travis-ci.org/alinex/node-ssh)
[![Coveralls status](
  https://img.shields.io/coveralls/alinex/node-ssh.svg?maxAge=2592000)](
  https://coveralls.io/r/alinex/node-ssh?branch=master)
[![Gemnasium status](
  https://img.shields.io/gemnasium/alinex/node-ssh.svg?maxAge=2592000)](
  https://gemnasium.com/alinex/node-ssh)
[![GitHub issues](
  https://img.shields.io/github/issues/alinex/node-ssh.svg?maxAge=2592000)](
  https://github.com/alinex/node-ssh/issues)
<!-- {.hidden-small} -->


Proxy ssh tunnel allows you to open tunnels through ssh connections which may be
used for communication.

A SSH tunnel consists of an encrypted tunnel created through a SSH protocol
connection. A SSH tunnel can be used to transfer unencrypted traffic over a
network through an encrypted channel. This may also be used to bypass firewalls
that prohibits or filter certain internet services.
If users can connect to an external SSH server, they can create a SSH tunnel to
forward a local port to a host and port reachable from the SSH server.

This module enables you to open and control such tunnels from your script while
they may be used also from external programs.

- outgoing tunneling through SSH
- pooling ssh connection for tunnels
- dynamic port forwarding using SOCKSv5 proxy
- configurable by file

> It is one of the modules of the [Alinex Namespace](https://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](https://alinex.github.io/develop).

__Read the complete documentation under
[https://alinex.github.io/node-ssh](https://alinex.github.io/node-ssh).__
<!-- {p: .hidden} -->


Install
-------------------------------------------------

[![NPM](https://nodei.co/npm/alinex-ssh.png?downloads=true&downloadRank=true&stars=true)
 ![Downloads](https://nodei.co/npm-dl/alinex-ssh.png?months=9&height=3)
](https://www.npmjs.com/package/alinex-ssh)

The easiest way is to let npm add the module directly to your modules
(from within you node modules directory):

``` sh
npm install alinex-ssh --save
```

And update it to the latest version later:

``` sh
npm update alinex-ssh --save
```

Always have a look at the latest [changes](Changelog.md).


Usage
-------------------------------------------------
This module has a very simple API, you can do two things:

### Simple forward tunnel

You can open a tunnel with:

``` coffee
ssh = require 'alinex-ssh'
ssh.open
  ssh:
    host: '65.25.98.25'
    port:  22
    username: 'root'
    #passphrase: 'mypass'
    privateKey: require('fs').readFileSync '/home/alex/.ssh/id_rsa'
    #localHostname: "Localost"
    #localUsername: "LocalUser"
    #readyTimeout: 20000
    keepaliveInterval: 1000
    #debug: true
  tunnel:
    host: '172.30.0.11'
    port: 80
    #localhost: '127.0.0.1'
    #localPort: 8080
  retry:
    times: 3
    intervall: 200
, (err, tunnel) ->
    console.log "tunnel opened at #{tunnel.setup.host}:#{tunnel.setup.port}"
    # wait 10 seconds, then close the tunnel
    setTimeout ->
      tunnel.end()
    , 10000
```

And afterwards you may close it like shown above using `tunnel.close()` or
close all tunnels with:

``` coffee
ssh.close()
```

### Dynamic SOCKSv5 Proxy

The following script shows how to make a dynamic 1:1 proxy using SOCKSv5. It's
nearly the same, only the tunnel host and port are missing (the tunnel group
may also be removed completely):

``` coffee
ssh = require 'alinex-ssh'
ssh.open
  ssh:
    host: '65.25.98.25'
    port:  22
    username: 'root'
    #passphrase: 'mypass'
    privateKey: require('fs').readFileSync '/home/alex/.ssh/id_rsa'
    #localHostname: "Localost"
    #localUsername: "LocalUser"
    #readyTimeout: 20000
    keepaliveInterval: 1000
    #debug: true
, (err, tunnel) ->
    console.log "tunnel opened at #{tunnel.setup.host}:#{tunnel.setup.port}"
    # wait 10 seconds, then close the tunnel
    setTimeout ->
      tunnel.end()
    , 10000
```

### Configuration files

To use configuration files you also need to setup and initialize this before using it:

``` coffee
ssh = require 'alinex-ssh'
ssh.setup (err) ->
  ssh.init (err) ->
    # do your work
```

See the {@link src/configSchema.coffee} for a detailed information about it's possibilities.
And then put your own settings in external files like described at {@link alinex-config}:

    /ssh.yaml - contains named setup of ssh connections
    /tunnel.yaml - set the tunnel configuration with name

But you may also directly give your setup to the methods above.


Debugging
----------------------------------------------
If you have any problems with the tunnel you may always run it with debugging by
only setting the `DEBUG` environment variable like:

``` coffee
DEBUG=ssh* myprog-usingssh
```

To get even more information you may also set the `debug` flag to `true` in the
setup of your ssh tunnel.

If you enable debugging of `ssh` the given configuration will also be validated.


License
-------------------------------------------------

(C) Copyright 2015-2016 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
