
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
exec = require('child_process').exec
path = require 'path'
fs = require 'fs'
# include alinex modules
util = require 'alinex-util'
config = require 'alinex-config'
# internal helpers
schema = require './configSchema'


# set the modules config paths and validation schema
exports.setup = setup = util.function.once this, (cb) ->
  # add schema for module's configuration
  config.setSchema '/ssh', schema.ssh, cb
  config.setSchema '/tunnel', schema.tunnel, cb

# set the modules config paths, validation schema and initialize the configuration
exports.init = init = util.function.once this, (cb) ->
  debug "initialize"
  # set module search path
  setup (err) ->
    return cb err if err
    config.init cb


# Control tunnel creation
# -------------------------------------------------
exports.open = (setup, cb) ->
  init (err) ->
    return cb err if err
    debug chalk.grey "open tunnel..."
    # add setup defaults
    optimize setup, (err, setup) ->
      return cb err if err
      # open ssh connection
      async.retry
        times: setup.retry?.times ? 1
        interval: setup.retry?.intervall ? 200
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
        async.each Object.keys(conn.tunnel), (tunnel, cb) ->
          spec = util.extend 'MODE CLONE', setup.tunnel,
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
        return cb() if entry.passphrase or entry.privateKey
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

# ### open ssh connection
connect = util.function.onceTime (setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, connections[name] if connections[name]?._sock?._handle
  # open new ssh
  debug chalk.grey "establish new ssh connection to #{name}"
  conn = new ssh.Client()
  conn.name = name
  conn.on 'ready', ->
    debug chalk.grey "#{conn.name}: ssh client ready"
    # store connection
    conn.tunnel ?= {}
    connections[name] = conn
    cb null, conn
  conn.on 'banner', (msg) ->
    debug chalk.yellow msg
  conn.on 'error', (err) ->
    debug chalk.magenta "#{conn.name}: got error: #{err.message}"
    conn.end()
    cb err
#    debug "reconnect ssh connection to #{name}"
#    conn.connect util.extend util.clone(setup),
#      debug: unless setup.debug then null else (msg) ->
#        debugDebug chalk.grey msg
  conn.on 'end', ->
    debug chalk.grey "#{conn.name}: ssh client closing"
    for tunnel of conn.tunnel
      tunnel.end?()
    delete connections[name]
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
  debug "#{conn.name}: open new tunnel to #{name}"
  findPort setup, (err, setup) ->
    return cb err if err
    setup.localHost ?= '127.0.0.1'
    debug chalk.grey "#{conn.name}: opening tunnel on local port
    #{setup.localHost}:#{setup.localPort}"
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
      debug "#{conn.name}: closing tunnel to #{name}"
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
  debug "#{conn.name}: open new tunnel to #{name}"
  findPort setup, (err, setup) ->
    return cb err if err
    setup.localHost ?= '127.0.0.1'
    debug chalk.grey "#{conn.name}: opening tunnel on local port
    #{setup.localHost}:#{setup.localPort}"
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
      debug "#{conn.name}: closing tunnel to #{name}"
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
