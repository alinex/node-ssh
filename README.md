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


SSH connection handling with the ability to open tunnels for further communications
and remote execution.

A SSH tunnel consists of an encrypted tunnel created through a SSH protocol
connection. A SSH tunnel can be used to transfer unencrypted traffic over a
network through an encrypted channel. This may also be used to bypass firewalls
that prohibits or filter certain internet services.
If users can connect to an external SSH server, they can create a SSH tunnel to
forward a local port to a host and port reachable from the SSH server.

This module enables you to open and control such remote connections from your script
and use them for execution or tunneling. The tunnels may also be used from external
commands.

- configurable ssh connections
- pooling ssh connection
- outgoing tunneling through SSH
- dynamic port forwarding using SOCKSv5 proxy
- cluster/group support

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
This module has a very simple API, you can do three things:

### Remote Connection

This is only a simple remote execution of a command line. To get more possibilities
use the {@link alinex-exec} module which internaly calls this method with the correct
commandline.

``` coffee
ssh = require 'alinex-ssh'
ssh.connect
  server:
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
  retry:
    times: 3
    intervall: 200
, (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    conn.close()
  , 10000
```

This may also be called with a list of alternative `server` connections.

#### Configured

Or the short versions if configured in the configuration files needs only a name
to reference the correct entry:

``` coffee
ssh = require 'alinex-ssh'
ssh.connect
  server: 'db'
  retry:
    times: 3
    intervall: 200
, (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    conn.close()
  , 10000
```

The retry part can also be kept away to use the defaults (from config).

The following is a short form, only possible if no special retry times are used:

``` coffee
ssh = require 'alinex-ssh'
ssh.connect 'db', (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    conn.close()
  , 10000
```

#### Cluster/Groups

Another possibility is to use a cluster or group to connect to the best server of
it:

``` coffee
ssh = require 'alinex-ssh'
ssh.connect
  group: 'appcluster'
, (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    conn.close()
  , 10000
```

Alternatively you can give the group as an array of server names or configurations:

``` coffee
ssh = require 'alinex-ssh'
ssh.connect
  group: ['node1', 'node2', 'node3']
, (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    conn.close()
  , 10000
```

And also the short version is possible which will first try to use the given name
as group else as server:

``` coffee
ssh = require 'alinex-ssh'
ssh.connect 'appcluster', (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    conn.close()
  , 10000
```

### Tunneling

#### Simple forward tunnel

You can open a tunnel with:

``` coffee
ssh = require 'alinex-ssh'
ssh.tunnel
  server:
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
    tunnel.close()
  , 10000
```

And afterwards you may close it like shown above using `tunnel.close()` or
close all tunnels with:

``` coffee
ssh.close()
```

Or the really short versions if configured in the configuration files:

``` coffee
ssh = require 'alinex-ssh'
ssh.tunnel
  tunnel: 'intranet'
  retry:
    times: 3
    intervall: 200
, (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    tunnel.close()
  , 10000
```

``` coffee
ssh = require 'alinex-ssh'
ssh.tunnel 'intranet', (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    tunnel.close()
  , 10000
```

#### Dynamic SOCKSv5 Proxy

The following script shows how to make a dynamic 1:1 proxy using SOCKSv5. It's
nearly the same, only the tunnel host and port are missing:

``` coffee
ssh = require 'alinex-ssh'
ssh.tunnel
  server:
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
    tunnel.close()
  , 10000
```

Or the really short versions if configured in the configuration files:

``` coffee
ssh = require 'alinex-ssh'
ssh.tunnel 'db', (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    tunnel.close()
  , 10000
```

#### Cluster/Group

Like in the use of connections you may use cluster or group names within the tunneling,
too. This means that the tunnel will be made through the best working host.

``` coffee
ssh = require 'alinex-ssh'
ssh.tunnel
  group: 'dmz'
  tunnel:
    host: '172.30.0.11'
    port: 80
  retry:
    times: 3
    intervall: 200
, (err, conn) ->
  console.log "ssh connection #{conn.name} opened"
  # wait 10 seconds, then close the tunnel
  setTimeout ->
    tunnel.close()
  , 10000
```

And if you use a preconfigured tunnel you may use the group reference name within
the tunnel's remote setting like the server name.

#### Configuration files

To use configuration files you also need to setup and initialize this before using it:

``` coffee
ssh = require 'alinex-ssh'
ssh.setup (err) ->
  ssh.init (err) ->
    # do your work
```

See the {@link src/configSchema.coffee} for a detailed information about it's possibilities.
And then put your own settings in external files like described at {@link alinex-config}:

    /ssh/server.yaml - contains named setup of ssh connections
    /ssh/group.yaml - cluster/group definition
    /ssh/tunnel.yaml - set the tunnel configuration with name

But you may also directly give your setup to the methods above.


### Remote Execution

To do this you have to use the {@link alinex-exec} module which internally connects
using this and also uses the same configuration files.


Tips and Tricks
----------------------------------------------

### Execute on whole Group

This may be done easily if you step over the configured list of servers of a group.
Mostly you have a cluster there and want to take the action on each of them but
seriously to don't disturb your app users.

``` coffee
config = require 'alinex-config'
async.eachSeries config.get('/ssh/group/appcluster'), (server, cb) ->
  # do something with this server like remote execution
, (err) ->
  # check for problems
```


Debugging
----------------------------------------------
If you have any problems with the tunnel you may always run it with debugging by
only setting the `DEBUG` environment variable like:

``` bash
DEBUG=ssh myprog-usingssh         # general ssh info
DEBUG=ssh:tunnel myprog-usingssh  # tunnel information
DEBUG=ssh:data myprog-usingssh    # output data send connection
DEBUG=ssh:debug myprog-usingssh   # output debug level (needs debug: true in server settings)
DEBUG=ssh* myprog-usingssh        # output alltogether
```

To get even more information you may also set the `debug` flag to `true` in the
setup of your ssh tunnel and enable `DEBUG=ssh:debug`.

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
