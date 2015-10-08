Package: alinex-sshtunnel
=================================================

[![Dependency Status](https://gemnasium.com/alinex/node-sshtunnel.png)](https://gemnasium.com/alinex/node-sshtunnel)

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
- using pooled ssh connections
- pooling also for the tunnels
- auto reconnect

> It is one of the modules of the [Alinex Universe](http://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](http://alinex.github.io/node-alinex).

Install
-------------------------------------------------

[![NPM](https://nodei.co/npm/alinex-sshtunnel.png?downloads=true&downloadRank=true&stars=true)
 ![Downloads](https://nodei.co/npm-dl/alinex-sshtunnel.png?months=9&height=3)
](https://www.npmjs.com/package/alinex-sshtunnel)

The easiest way is to let npm add the module directly to your modules
(from within you node modules directory):

``` sh
npm install alinex-sshtunnel --save
```

And update it to the latest version later:

``` sh
npm update alinex-sshtunnel --save
```

Always have a look at the latest [changes](Changelog.md).


Usage
-------------------------------------------------
This module has a very simple API, you can do two things:

First you can open a tunnel:

``` coffee
sshtunnel = require 'alinex-sshtunnel'
sshtunnel
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
, (err, tunnel) ->
    console.log "tunnel opened at #{tunnel.setup.host}:#{tunnel.setup.port}"
    # wait 10 seconds, then close the tunnel
    setTimeout ->
      tunnel.close()
      cb()
    , 10000
```

And afterwards you may close it like shown above using `tunnel.close()` or
close all tunnels with:

``` coffee
sshtunnel.close()
```

License
-------------------------------------------------

Copyright 2015 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
