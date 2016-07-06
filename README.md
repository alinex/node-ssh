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
- dynamic port forwarding using SOCKSv5 proxy

> It is one of the modules of the [Alinex Universe](http://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](http://alinex.github.io/develop).

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

### Simple forward tunnel

You can open a tunnel with:

``` coffee
sshtunnel = require 'alinex-sshtunnel'
sshtunnel.open
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
sshtunnel.close()
```

### Dynamic SOCKSv5 Proxy

The following script shows how to make a dynamic 1:1 proxy using SOCKSv5. It's
nearly the same, only the tunnel host and port are missing (the tunnel group
may also be removed completely):

``` coffee
sshtunnel = require 'alinex-sshtunnel'
sshtunnel.open
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
sshtunnel = require 'alinex-sshtunnel'
sshtunnel.setup (err) ->
  sshtunnel.init (err) ->
    # do your work
```

### Debugging

If you have any problems with the tunnel you may always run it with debugging by
only setting the `DEBUG` environment variable like:

``` coffee
DEBUG=sshtunnel* myprog-usingsshtunnel
```

To get even more information you may also set the `debug` flag to `true` in the
setup of your ssh tunnel.


Setup
-------------------------------------------------

Like shown above you may use several settings to specify your tunneling.

The `ssh` connection setup:

- `host` - define the host to bind the tunnel to as hostname or ip address
- `port` - the ssh port on the above host (default: 22)
- `forceIPv4` - set to `true` to only use resolved IPv4 address for host (default: false)
- `forceIPv6` - set to `true` to only use resolved IPv6 address for host (default: false)
- `username` - the user under which to connect (default: <your username>)
- `passphrase` - password for the above user (or privateKey)
- `privateKey` - private key, content to use (default: <use keys from .ssh dir>)
- `localHostname` - along with localUsername and privateKey for hostbased user authentication
- `localUsername` - along with localHostname and privateKey for hostbased user authentication
- `keepaliveInterval` - how often (in milliseconds) to send SSH-level keepalive packets
  to the server (default: 0 to disable)
- `keepaliveCountMax` - how many consecutive, unanswered SSH-level keepalive packets that can
  be sent to the server before disconnection (default: 3)
- `readyTimeout` - how long (in milliseconds) to wait for the SSH handshake to complete
  (default: 20000)
- `strictVendor` - performs a strict server vendor check before sending vendor-specific
  requests, etc. (default: true)
- `algorithms` - this option allows you to explicitly override the default transport
  layer algorithms used for the connection. The order of the algorithms in the arrays
  are important, with the most favorable being first.
  - `kex` - (array) Key exchange algorithms
  - `cipher` - (array) Ciphers
  - `serverHostKey` - (array) Server host key formats
  - `hmac` - (array) (H)MAC algorithms
  - `compress` - (array) Compression algorithms
- `compress` - set to `true` to enable compression if server supports it, `'force'` to
  force compression (disconnecting if server does not support it), or `false` to explicitly
  opt out of compression all of the time. (only possible if no algorithms defined)
- `debug` - also log detailed debug messages if `DEBUG=sshtunnel:debug` is set as
  environment variable (default: false)

> You may also provide an Array for the `ssh` setting. The module will try each server
> setup in order to get a working connection and uses the first one succeding.

For a simple tunnel you also have to define which connection you want to tunnel
in setting `tunnel`:

- `host` - hostname or ip address which to tunnel
- `port` - port to tunnel
- `localhost` - local ip where the tunnel will be setup (default: 127.0.0.1)
- `localPort` - local port to bind to the tunnel (default: 8000)

And finally to make connecting more robust you may add a retry setting which will
lead to a retry on problems while connecting. Short network problems won't make a
problem here (using `retry`):

- `times` - number of times to try to connect
- `intervall` - intervall to wait (in milliseconds) between tries

### Configuration

You may also put your configuration in external files using [config](http://alinex.github.io/node-config).

    /ssh.yaml - contains named setup of ssh connections
    /tunnel.yaml - set the tunnel configuration with name

Both of them needs the above documented settings. Now you may put your settings
outside of code with less effort.


License
-------------------------------------------------

Copyright 2015-2016 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
