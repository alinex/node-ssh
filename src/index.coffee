
###
SSH Connection class - API Usage
=================================================
This is an object oriented implementation arround the core `process.spawn`
command and alternatively ssh connections.
###


# Node Modules
# -------------------------------------------------
debug = require('debug')('ssh')
debugTunnel = require('debug')('ssh:tunnel')
debugData = require('debug')('ssh:data')
debugDebug = require('debug')('ssh:debug')
chalk = require 'chalk'
async = require 'async'
net = require 'net'
ssh = require 'ssh2'
portfinder = require 'portfinder'
exec = require('child_process').exec
path = require 'path'
fs = require 'fs'
# include alinex modules
util = require 'alinex-util'
config = require 'alinex-config'
validator = null # loaded on demand
# internal helpers
schema = require './configSchema'


###
Setup
-------------------------------------------------
###

###
Set the modules config paths and validation schema.

@param {Function(Error)} cb callback with `Error` if something went wrong
###
exports.setup = setup = util.function.once this, (cb) ->
  # add schema for module's configuration
  config.setSchema '/ssh', schema, cb

###
Set the modules config paths, validation schema and initialize the configuration

@param {Function(Error)} cb callback with `Error` if something went wrong
###
exports.init = init = util.function.once this, (cb) ->
  debug "initialize"
  # set module search path
  setup (err) ->
    return cb err if err
    config.init cb

# Map of ssh connections.
#
# @type {Client} SSH client connection
# - `config` - `Object` with all settings of the connection (ssh2 format)
# - `name` - `String` name identifying the server
# - `tunnel` - `Object` map of opened tunnels
# - `process` - `Object` map of running executions on this connection
# - `close` -  `Function` to close the connection and everything build upon it
connections = {}

# Vital data of some hosts
#
# @type {Object<Object>} vital data of host with
# - `date` - minute of measurement
# - `free` - free sources
vitalStore = {}


###
Open Remote Connections
-------------------------------------------------
###

###
Open anew connection to run remote commands.
To close it again you have to call `conn.close()` but keep
in mind that this will close the connection for all runing commands and tunnels
because they are shared. So better only close it if you know you no longer need
it or at the end of your script using `ssh.close()`.

@param {Object} setup the server settings
- `server` {@schema configSchema.coffee#keys/server/entries/0}
- `group` {@schema configSchema.coffee#keys/group/entries/0}
- `retry` {@schema configSchema.coffee#keys/retry}
@param {Function(Error, Connection)} cb callback with error if something went wrong
and the ssh connection on success containing
###
exports.connect = (setup, cb) ->
  # resolve setup
  try
    setup = resolveServer setup
  catch error
    return cb error
  # check the setup
  if debug.enabled
    validator ?= require 'alinex-validator'
    try
      if setup.server
        validator.checkSync
          name: 'sshServerSetup'
          title: "SSH Connection to Open"
          value: setup.server
          schema: schema.keys.group.entries[0].entries
      if setup.group
        validator.checkSync
          name: 'sshGroupSetup'
          title: "SSH Group to Connect"
          value: setup.group
          schema: schema.keys.group.entries[0]
      if setup.retry
        validator.checkSync
          name: 'sshRetrySetup'
          title: "SSH Retry Settings"
          value: setup.retry
          schema: schema.keys.retry
    catch error
      debug "called with " + util.inspect setup, {depth: null}
      throw error
  init (err) ->
    return cb err if err
    # get best server of group
    groupResolve setup, (err, setup) ->
      return cb err if err
      # add setup defaults
      optimize setup, (err, setup) ->
        return cb err if err
        # open ssh connection
        retry = config.get "/ssh/retry"
        async.retry
          times: setup.retry?.times ? retry ? 1
          interval: setup.retry?.interval ? retry ? 200
        , (cb) ->
          problems = []
          async.mapSeries setup.server, (entry, cb) ->
            # try each connection setting till one works
            open entry, (err, conn) ->
              problems.push err.message if err
              return cb() unless conn
              cb 'STOP', conn
          , (_, result) ->
            # the last entry should be a connection
            conn = result.pop() # the last result
            unless conn
              return cb new Error "Connecting to server impossible!\n" + problems.join "\n"
            conn.tunnel = {}
            conn.process = {}
            cb null, conn
        , cb

# Resolve the server setting into the best fitting entry.
#
# @param {Object} setup the server settings in different forms
# @return {Connection} ssh connection on success containing
resolveServer = (setup) ->
  # get setup values corrected
  if typeof setup is 'string'
    # short references used
    if group = config.get "/ssh/group/#{setup}"
      setup =
        group: group
    else if server = config.get "/ssh/server/#{setup}"
      setup =
        server: server
    else
      throw new Error "Could not find group or server in ssh configuration with name '#{setup}'"
  # server object to array
  if typeof setup.server is 'object' and not Array.isArray setup.server
    setup.server = [setup.server]
  if typeof setup.group is 'string'
    unless group = config.get "/ssh/group/#{setup.group}"
      throw new Error "Could not find group in ssh configuration with name '#{setup.group}'"
    setup.group = group
  return setup

# Resolve the group setting into the best fitting entry.
#
# @param {Object} setup the server settings
# - `server` {@schema configSchema.coffee#keys/server/entries/0}
# - `group` {@schema configSchema.coffee#keys/group/entries/0}
# - `retry` {@schema configSchema.coffee#keys/retry}
# @param {Function(Error, Connection)} cb callback with error if something went wrong
# and the ssh connection on success containing
groupResolve = (setup, cb) ->
  return cb null, setup unless setup.group
  debug chalk.grey "check group for best value..." if debug.enabled
  now = new Date().getTime()
  check = now - 60000
  async.map setup.group, (server, cb) ->
    # resolve setup
    try
      server = resolveServer(server).server
    catch error
      return cb error
    # get already measured value
    name = server[0].host
    if vitalStore[name]?.date > check
      exports.connect
      return cb null,
        server: server
        free: vitalStore[name].free
    # get vital data
    exports.connect
      server: server
      retry:
        times: 0
    , (err, conn) ->
      if err
        debug chalk.magenta err.message if debug.enabled
        vitalStore[name] =
          date: now
          free: -100
        return cb null,
          server: server
          free: -10
      conn.exec 'nproc && cat /proc/loadavg', (err, stream) ->
        buffer = ""
        if err
          debug chalk.magenta err.message if debug.enabled
          vitalStore[name] =
            date: now
            free: -10
          return cb null,
            server: server
            free: -10
        stream.on 'data', (data) -> buffer += data.toString()
        stream.on 'end', ->
          data = buffer.split /\s+/
          free = data[0] - data[1]
          debug chalk.grey "#{conn.name}: vital data free: #{free}" if debug.enabled
          vitalStore[name] =
            date: now
            free: free
          cb null,
            server: server
            free: free
  , (err, result) ->
    return cb err if err
    result = util.array.sortBy result, '-free'
    if debug.enabled
      debug "#{result[0].server[0].host}: selected from cluster/group"
    cb null,
      server: result[0].server
      retry: setup.retry
    for entry of result[1..]
      continue unless entry.conn?
      continue if Object.keys(entry.conn.tunnel) or Object.keys(entry.conn.process)
      entry.conn.close()


###
Control tunnel creation
-------------------------------------------------
###

###
Open new tunnel. It may be closed by calling `tunnel.close()`. This will close
the tunnel but keeps the connection opened.

@param {Object} setup the server settings
- `server` {@schema configSchema.coffee#keys/server/entries/0}
- `tunnel` {@schema configSchema.coffee#keys/tunnel/entries/0}
But the `remote` server may be missing then the given `server` setting is used.
If the `host` and `port` setting is not given a socks5 proxy tunnel will be opened.
- `retry` {@schema configSchema.coffee#keys/retry}
@param {Function(Error, Object)} cb callback with error if something went wrong
or the tunnel information on success
###
exports.tunnel = (setup, cb) ->
  # resolve string only value
  if typeof setup is 'string'
    if conf = config.get "/ssh/tunnel/#{setup}"
      setup =
        tunnel: conf
    else if conf = config.get "/ssh/group/#{setup}"
      setup =
        group: conf
    else if conf = config.get "/ssh/server/#{setup}"
      setup =
        server: conf
    else
      return cb new Error "Could not find tunnel, group or server in ssh configuration
      with name '#{setup}'"
  # resolve tunnel setting
  if setup.tunnel? and typeof setup.tunnel is 'string'
    if conf = config.get "/ssh/tunnel/#{setup}"
      setup.tunnel = conf
    else
      return cb new Error "Could not find tunnel in ssh configuration with name '#{setup}'"
  # resolve remote setting in tunnel
  if setup.tunnel?.remote
    if conf = config.get "/ssh/group/#{setup.tunnel.remote}"
      setup.group = conf
    else if conf = config.get "/ssh/server/#{setup.tunnel.remote}"
      setup.server = conf
    else
      return cb new Error "Could not find group or server in ssh configuration
      with name '#{setup.tunnel.remote}'"
  # connect
  exports.connect setup, (err, conn) ->
    setup.tunnel ?= {}
    setup.tunnel.remote ?= setup.server
    if debugTunnel.enabled
      validator ?= require 'alinex-validator'
      validator.checkSync
        name: 'sshTunnelSetup'
        title: "SSH Tunnel to Open"
        value: setup.tunnel
        schema: schema.keys.tunnel.entries[0]
    return cb err if err
    if setup.tunnel?.host and setup.tunnel?.port
      # open new tunnel
      forward conn, setup.tunnel, (err, tunnel) ->
        return cb err if err
        cb null, tunnel
    else
      # open SOCKSv5 proxy
      proxy conn, setup.tunnel, (err, tunnel) ->
        return cb err if err
        cb null, tunnel

###
Close all tunnels and ssh connections.

This will end all operations and should be called on shutdown.
###
exports.close = ->
  conn.close() for conn in connections


# Helper methods
# -------------------------------------------------

# Optimize settings and add defaults. If only a reference name is given, this will
# be replaced with the configured settings. And the user's name and his private keys
# will be auto detected if stored in the default place. In case of multiple private
# keys the list will get multiple copies of the origin entry with each key.
#
# @param {Object|String} setup like described in {@link configSchema.coffee} or
# reference to configured connection
# @param {Function(Error, Object)} cb callback with `Error` if something went wrong
# or the optimized setup
optimize = (setup, cb) ->
  # use configuration
  if typeof setup is 'string'
    setup.server = config.get "/ssh/server/#{setup}"
  if typeof setup.server is 'string'
    server = config.get "/ssh/server/#{setup.server}"
    unless server
      return cb new Error "No server configured under /ssh/server/#{setup.server}"
    setup.server = server
  # optimize settings with defaults
  setup.server = [setup.server] unless Array.isArray setup.server
  async.each setup.server, (entry, cb) ->
    async.parallel [
      (cb) ->
        return cb() if entry.username
        # auto detect user name from system
        if process.env.USERPROFILE
          entry.username = process.env.USERPROFILE.split(path.sep)[2]
          return cb()
        entry.username = process.env.USER ? process.env.USERNAME
        return cb() if entry.username
        exec 'whoami',
          encoding: 'utf8'
        , (err, name) ->
          entry.username = name?.trim()
          cb err
      (cb) ->
        return cb() if entry.password or entry.privateKey
        # auto read the private keys and make a setting for each one found
        home = if process.platform is 'win32' then 'USERPROFILE' else 'HOME'
        dir = "#{process.env[home]}/.ssh"
        # search for ssh keys
        fs.readdir dir, (err, files) ->
          return cb() if err or not files.length
          async.each files, (file, cb) ->
            fs.readFile "#{dir}/#{file}", 'utf8', (err, content) ->
              return cb() if err
              return cb() unless content.match /-----BEGIN .*? PRIVATE KEY-----/
              setup.server.push util.extend util.clone(entry),
                privateKey: content
              cb()
          , cb
    ], cb
  , (err) ->
    cb err, setup

# Open ssh connection.
#
# @param {Object} setup like described in {@link configSchema.coffee}
# @param {Function(Error, Connection)} cb callback with `Error` if something went wrong
# or the Connection with:
# - `name` - `String` with host/ip and port
# - `tunnel` - `Object<Server>` with the opened tunnels
open = util.function.onceTime (setup, cb) ->
  name = setup.host
  if connections[name]?._sock?._handle
    debug "#{name}: use existing connection" if debug.enabled
    return cb null, connections[name]
  # open new ssh
  if debug.enabled
    debug chalk.grey "#{name}: establish new ssh connection"
    debugDebug chalk.grey util.inspect(setup).replace /\n/g, '' if debugDebug.enabled
  conn = new ssh.Client()
  conn.name = name
  conn.close = ->
    delete connections[name]
    return if conn._sock?._handle
    conn.end()
    conn.emit 'end'
  conn.on 'ready', ->
    debug chalk.grey "#{conn.name}: ssh client ready" if debug.enabled
    # store connection
    connections[name] = conn
    cb null, conn
  if debug.enabled
    conn.on 'banner', (msg) ->
      debug chalk.yellow msg
  conn.on 'error', (err) ->
    debug chalk.magenta "#{conn.name}: got error: #{err.message}" if debug.enabled
    conn.close()
    cb err
  conn.on 'end', ->
    debug chalk.grey "#{conn.name}: ssh client closed" if debug.enabled
    for tunnel of conn.tunnel
      tunnel.end?()
    delete connections[name]
  # start connection
  conn.connect util.extend util.clone(setup),
    debug: unless setup.debug then null else (msg) ->
      if debugDebug.enabled
        debugDebug chalk.grey msg.replace /DEBUG/, conn.name

# Snip communication strings for debugging.
#
# @param {String} data communication string from ssh connection
# @return {String} simplified string
snip = (data) ->
  text = util.inspect data.toString()
  text = text[0..30] + '...\'' if text.length > 30
  text

# Open Outgoing Tunnel.
#
# @param {Connection} conn the ssh connection
# @param {Object} setup for tunnel like described in {@link configSchema.coffee#tunnel-settings}
# @param {Function(Error, Server)} cb callback with `Error` if something went wrong
# or the working server tunnel
forward = (conn, setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, conn.tunnel[name] if conn.tunnel[name]
  # make new tunnel
  debugTunnel "#{conn.name}: open new tunnel to #{name}" if debugTunnel.enabled
  findPort setup, (err, setup) ->
    return cb err if err
    setup.localHost ?= '127.0.0.1'
    if debugTunnel.enabled
      debugTunnel chalk.grey "#{conn.name}: opening tunnel on local port
      #{setup.localHost}:#{setup.localPort}"
    tunnel = net.createServer (sock) ->
      conn.forwardOut sock.remoteAddress, sock.remotePort, setup.host, setup.port, (err, stream) ->
        if err
          return tunnel.end()
        sock.pipe stream
        stream.pipe sock
        if debugData.enabled
          sock.on 'data', (data) -> debugData chalk.grey "request : #{snip data}"
          stream.on 'data', (data) -> debugData chalk.grey "response: #{snip data}"
    tunnel.end = ->
      try
        tunnel.close()
    tunnel.on 'close', ->
      debugTunnel "#{conn.name}: closing tunnel to #{name}" if debugTunnel.enabled
      delete conn.tunnel[name]
      unless Object.keys(conn.tunnel).length
        unless Object.keys(conn.process).length
          conn.close()
    tunnel.setup =
      host: setup.localHost
      port: setup.localPort
    conn.tunnel[name] = tunnel
    # return running tunnel
    tunnel.listen setup.localPort, setup.localHost, ->
      cb null, tunnel

# Open outgoin tunnel.
#
# @param {Connection} conn the ssh connection
# @param {Object} setup for tunnel like described in {@link configSchema.coffee#tunnel-settings}
# @param {Function(Error, Server)} cb callback with `Error` if something went wrong
# or the working server tunnel
proxy = (conn, setup = {}, cb) ->
  socks = require 'socksv5'
  name = "socksv5 proxy"
  return cb null, conn.tunnel[name] if conn.tunnel[name]
  # make new tunnel
  debugTunnel "#{conn.name}: open new tunnel to #{name}" if debugTunnel.enabled
  findPort setup, (err, setup) ->
    return cb err if err
    setup.localHost ?= '127.0.0.1'
    if debugTunnel.enabled
      debugTunnel chalk.grey "#{conn.name}: opening tunnel on local port
      #{setup.localHost}:#{setup.localPort}"
    tunnel = socks.createServer (info, accept) ->
      conn.forwardOut info.srcAddr, info.srcPort, info.dstAddr, info.dstPort, (err, stream) ->
        if err
          return tunnel.end()
        if sock = accept(true)
          sock.pipe stream
          stream.pipe sock
          if debugData.enabled
            sock.on 'data', (data) -> debugData chalk.grey "request : #{snip data}"
            stream.on 'data', (data) -> debugData chalk.grey "response: #{snip data}"
        else
          tunnel.end()
    tunnel.end = ->
      try
        tunnel.close()
    tunnel.on 'close', ->
      debugTunnel "#{conn.name}: closing tunnel to #{name}" if debugTunnel.enabled
      delete conn.tunnel[name]
      unless Object.keys(conn.tunnel).length
        conn.close()
    tunnel.setup =
      host: setup.localHost
      port: setup.localPort
    conn.tunnel[name] = tunnel
    # return running tunnel
    tunnel.useAuth socks.auth.None()
    tunnel.listen setup.localPort, setup.localHost, ->
      cb null, tunnel

# Find an unused port and add it to setup.
#
# @param {Object} setup for tunnel like described in {@link configSchema.coffee#tunnel-settings}
# @param {Function(Error, Object)} cb callback with `Error` if something went wrong
# or the optimized setup
findPort = (setup, cb) ->
  portfinder.basePort = setup.localPort ? 8000
  portfinder.getPort (err, port) ->
    return cb err if err
    if debug.enabled and setup.localPort? and port isnt setup.localPort
      debug chalk.magenta "given port #{setup.localPort} is blocked using #{port}"
    setup.localPort = port
    return cb null, setup
