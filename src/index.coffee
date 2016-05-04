
# SSH Tunneling class
# =================================================
# This is an object oriented implementation around the core `process.spawn`
# command and alternatively ssh connections.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('sshtunnel')
debugData = require('debug')('sshtunnel:data')
debugDebug = require('debug')('sshtunnel:debug')
chalk = require 'chalk'
async = require 'async'
net = require 'net'
ssh = require 'ssh2'
portfinder = require 'portfinder'
# include alinex modules
util = require 'alinex-util'

# Control tunnel creation
# -------------------------------------------------
module.exports = (setup, cb) ->
  debug chalk.grey "init tunnel..."
  # open ssh connection
  connect setup.ssh, (err, conn) ->
    return cb err if err
    # reopen already setup tunnels
    async.each Object.keys(conn.tunnel), (tunnel, cb) ->
      spec = util.extend 'MODE CLONE', setup.tunel,
        localHost: tunnel.setup.host
        localPort: tunnel.setup.port
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
# map of ssh connections
connections = {}

# Helper methods
# -------------------------------------------------

# ### open ssh connection
connect = util.function.onceTime (setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, connections[name] if connections[name]?._sock?._handle
  # open new ssh
  debug chalk.grey "establish new ssh connection to #{name}"
  conn = new ssh.Client()
  conn.on 'ready', ->
    debug chalk.grey "ssh client ready"
    # store connection
    conn.tunnel ?= {}
    connections[name] = conn
    cb null, conn
  conn.on 'banner', (msg) ->
    debug chalk.yellow msg
  conn.on 'error', (err) ->
    debug chalk.magenta "got error: #{err.message}"
    conn.end()
    debug "reconnect ssh connection to #{name}"
    conn.connect util.extend 'MODE CLONE', setup,
      debug: unless setup.debug then null else (msg) ->
        debugDebug chalk.grey msg
  conn.on 'end', ->
    debug chalk.grey "ssh client closing"
    delete connections[name]
    for tunnel of conn.tunnel
      tunnel.end()
  # start connection
  conn.connect util.extend util.clone(setup),
    debug: unless setup.debug then null else (msg) ->
      debugDebug chalk.grey msg

# ### snip communication strings for debugging
snip = (data) ->
  text = util.inspect data.toString()
  text = text[0..30] + '...\'' if text.length > 30
  text

# ### open outgoin tunnel
forward = (conn, setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, conn.tunnel[name] if conn.tunnel[name]
  # make new tunnel
  debug "open new tunnel to #{name}"
  findPort setup, (err, setup) ->
    return cb err if err
    setup.localHost ?= '127.0.0.1'
    debug chalk.grey "opening tunnel on local port #{setup.localHost}:#{setup.localPort}"
    tunnel = net.createServer (sock) ->
      conn.forwardOut sock.remoteAddress, sock.remotePort, setup.host, setup.port, (err, stream) ->
        if err
          return tunnel.end()
        sock.pipe stream
        stream.pipe sock
        sock.on 'data', (data) -> debugData chalk.grey "request : #{snip data}"
        stream.on 'data', (data) -> debugData chalk.grey "response: #{snip data}"
    tunnel.end = ->
      try
        tunnel.close()
    tunnel.on 'close', ->
      debug "closing tunnel to #{name}"
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

# ### open outgoin tunnel
proxy = (conn, setup = {}, cb) ->
  socks = require 'socksv5'
  name = "socksv5 proxy"
  return cb null, conn.tunnel[name] if conn.tunnel[name]
  # make new tunnel
  debug "open new tunnel to #{name}"
  findPort setup, (err, setup) ->
    return cb err if err
    setup.localHost ?= '127.0.0.1'
    debug chalk.grey "opening tunnel on local port #{setup.localHost}:#{setup.localPort}"
    tunnel = socks.createServer (info, accept) ->
      conn.forwardOut info.srcAddr, info.srcPort, info.dstAddr, info.dstPort, (err, stream) ->
        if err
          return tunnel.end()
        if sock = accept(true)
          sock.pipe stream
          stream.pipe sock
          sock.on 'data', (data) -> debugData chalk.grey "request : #{snip data}"
          stream.on 'data', (data) -> debugData chalk.grey "response: #{snip data}"
        else
          tunnel.end()
    tunnel.end = ->
      try
        tunnel.close()
    tunnel.on 'close', ->
      debug "closing tunnel to #{name}"
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

# ### find an unused port
findPort = (setup, cb) ->
  portfinder.basePort = setup.localPort ? 8000
  portfinder.getPort (err, port) ->
    return cb err if err
    if setup.localPort? and port isnt setup.localPort
      debug chalk.magenta "given port #{setup.localPort} is blocked using #{port}"
    setup.localPort = port
    return cb null, setup

# ### close all tunnels and ssh connections
exports.close = ->
  conn.end() for conn in connections
