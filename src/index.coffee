# SSH Tunneling class
# =================================================
# This is an object oriented implementation around the core `process.spawn`
# command and alternatively ssh connections.


# Node Modules
# -------------------------------------------------
debug = require('debug')('sshtunnel')
debugData = require('debug')('sshtunnel:data')
debugDebug = require('debug')('sshtunnel:debug')
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


# Setup
# -------------------------------------------------

# Set the modules config paths and validation schema.
#
# @param {Function(Error)} cb callback with `Error` if something went wrong
exports.setup = setup = util.function.once this, (cb) ->
  # add schema for module's configuration
  config.setSchema '/ssh', schema.ssh, (err) ->
    return cb err if err
    config.setSchema '/tunnel', schema.tunnel, cb

# Set the modules config paths, validation schema and initialize the configuration
#
# @param {Function(Error)} cb callback with `Error` if something went wrong
exports.init = init = util.function.once this, (cb) ->
  debug "initialize"
  # set module search path
  setup (err) ->
    return cb err if err
    config.init cb

# Map of ssh connections.
#
# @type {Object}
connections = {}


# Control tunnel creation
# -------------------------------------------------

# Open new tunnel.
#
# @param {Object} setup like described in {@link configSchema.coffee}
# @param {Function(Error, Object)} cb callback with `Error` if something went wrong
# or with the tunnel specification if it was opened
exports.open = (setup, cb) ->
  if debug.enabled
    validator ?= require 'alinex-validator'
    validator.checkSync
      name: 'sshTunnelSetup'
      title: "SSH Tunnel to Open"
      value: setup
      schema: schema.tunnel
  init (err) ->
    return cb err if err
    debug chalk.grey "open tunnel..." if debug.enabled
    # add setup defaults
    optimize setup, (err, setup) ->
      return cb err if err
      # open ssh connection
      async.retry
        times: setup.retry?.times ? 1
        interval: setup.retry?.interval ? 200
      , (cb) ->
        problems = []
        async.mapSeries setup.ssh, (entry, cb) ->
          # try each connection setting till one works
          connect entry, (err, conn) ->
            problems.push err.message if err
            return cb() unless conn
            cb 'STOP', conn
        , (_, result) ->
          # the last entry should be a connection
          conn = result.pop()
          return cb new Error "Connecting to server impossible!\n" + problems.join '\n' unless conn
          cb null, conn
      , (err, conn) ->
        return cb err if err
        # reopen already setup tunnels
        async.each Object.keys(conn.tunnel), (tk, cb) ->
          spec = util.extend 'MODE CLONE', setup.tunnel,
            localHost: conn.tunnel[tk].setup.host
            localPort: conn.tunnel[tk].setup.port
          forward conn, spec, cb
        , (err) ->
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

# Open ssh connection.
#
# @param {Object} setup like described in {@link configSchema.coffee}
# @param {Function(Error, Connection)} cb callback with `Error` if something went wrong
# or the Connection with:
# - `name` - `String` with host/ip and port
# - `tunnel` - `Object<Server>` with the opened tunnels
exports.connect = connect = util.function.onceTime (setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, connections[name] if connections[name]?._sock?._handle
  # open new ssh
  debug chalk.grey "establish new ssh connection to #{name}" if debug.enabled
  conn = new ssh.Client()
  conn.name = name
  conn.on 'ready', ->
    debug chalk.grey "#{conn.name}: ssh client ready" if debug.enabled
    # store connection
    conn.tunnel ?= {}
    connections[name] = conn
    cb null, conn
  if debug.enabled
    conn.on 'banner', (msg) ->
      debug chalk.yellow msg
  conn.on 'error', (err) ->
    debug chalk.magenta "#{conn.name}: got error: #{err.message}" if debug.enabled
    conn.end()
    cb err
  conn.on 'end', ->
    debug chalk.grey "#{conn.name}: ssh client closing" if debug.enabled
    for tunnel of conn.tunnel
      tunnel.end?()
    delete connections[name]
  # start connection
  conn.connect util.extend util.clone(setup),
    debug: unless setup.debug then null else (msg) ->
      debugDebug chalk.grey msg if debugDebug.enabled


# Helper methods
# -------------------------------------------------

# Optimize settings and add defaults. This includes the detection of the user's name
# and his private keys if stored in the default place. In case of multiple private
# keys the list will get multiple copies of the origin entry with each key.
#
# @param {Object} setup like described in {@link configSchema.coffee}
# @param {Function(Error, Object)} cb callback with `Error` if something went wrong
# or the optimized setup
optimize = (setup, cb) ->
  # use configuration
  if typeof setup is 'string'
    setup.ssh = config.get "/tunnel/#{setup}"
  if typeof setup.ssh is 'string'
    setup.ssh = config.get "/ssh/#{setup.ssh}"
  # optimize settings with defaults
  setup.ssh = [setup.ssh] unless Array.isArray setup.ssh
  async.each setup.ssh, (entry, cb) ->
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
              setup.ssh.push util.extend util.clone(entry),
                privateKey: content
              cb()
          , cb
    ], cb
  , (err) ->
    cb err, setup

# Snip communication strings for debugging.
#
# @param {String} data communication string from ssh connection
# @return {String} simplified string
snip = (data) ->
  text = util.inspect data.toString()
  text = text[0..30] + '...\'' if text.length > 30
  text

# Open Outgoing Tunnel
#
# @param {Connection} conn the ssh connection
# @param {Object} setup for tunnel like described in {@link configSchema.coffee#tunnel-settings}
# @param {Function(Error, Server)} cb callback with `Error` if something went wrong
# or the working server tunnel
forward = (conn, setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, conn.tunnel[name] if conn.tunnel[name]
  # make new tunnel
  debug "#{conn.name}: open new tunnel to #{name}" if debug.enabled
  findPort setup, (err, setup) ->
    return cb err if err
    setup.localHost ?= '127.0.0.1'
    if debug.enabled
      debug chalk.grey "#{conn.name}: opening tunnel on local port
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
      debug "#{conn.name}: closing tunnel to #{name}" if debug.enabled
      delete conn.tunnel[name]
      unless Object.keys(conn.tunnel).length
        conn.end()
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
  debug "#{conn.name}: open new tunnel to #{name}" if debug.enabled
  findPort setup, (err, setup) ->
    return cb err if err
    setup.localHost ?= '127.0.0.1'
    if debug.enabled
      debug chalk.grey "#{conn.name}: opening tunnel on local port
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
      debug "#{conn.name}: closing tunnel to #{name}" if debug.enabled
      delete conn.tunnel[name]
      unless Object.keys(conn.tunnel).length
        conn.end()
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

# Close all tunnels and ssh connections.
#
# This will end all operations and should be called on shutdown.
exports.close = ->
  conn.end() for conn in connections
