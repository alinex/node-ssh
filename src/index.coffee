
# SSH Tunneling class
# =================================================
# This is an object oriented implementation around the core `process.spawn`
# command and alternatively ssh connections.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('sshtunnel')
debugData = require('debug')('sshtunnel:data')
chalk = require 'chalk'
net = require 'net'
ssh = require 'ssh2'
util = require 'util'
portfinder = require 'portfinder'
# include alinex modules
async = require 'alinex-async'

# Setup
# -------------------------------------------------
portfinder.basePort = 8000

# Instantiation
# -------------------------------------------------
module.exports = open = (setup, cb) ->
  debug "require tunneling of #{setup.tunnel.host}:#{setup.tunnel.port}
  through #{setup.ssh.host}:#{setup.ssh.port}"
  connect setup.ssh, (err, conn) ->
    return cb err if err
    forward conn, setup.tunnel, (err, tunnel) ->
      return cb err if err
      cb null, tunnel

connections = {}
connect = async.onceTime (setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, connections[name] if connections[name]
  # open new ssh
  debug chalk.grey "establish new ssh connection to #{name}"
  conn = new ssh.Client()
  conn.on 'ready', ->
    debug chalk.grey "ssh client ready"
    # store connection
    conn.tunnel = {}
    connections[name] = conn
    cb null, conn
  conn.on 'close', ->
    debug chalk.grey "ssh client closing"
    for tunnel of conn.tunnel
      tunnel.close()
  # start connection
  conn.connect setup

snip = (data) ->
  text = util.inspect data.toString()
  text = text[0..30] + '...\'' if text.length > 30
  text

forward = (conn, setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, conn.tunnel[name] if conn.tunnel[name]
  # make new tunnel
  debug chalk.grey "open new tunnel to #{name}"
  findPort setup, (err, setup) ->
    return cb err if err
    setup.localHost ?= '127.0.0.1'
    debug chalk.grey "opening tunnel on local port #{setup.localHost}:#{setup.localPort}"
    tunnel = net.createServer (sock) ->
      conn.forwardOut sock.remoteAddress, sock.remotePort, setup.host, setup.port, (err, stream) ->
        if err
          tunnel.end()
          return cb err
        sock.on 'data', (data) -> debugData chalk.grey "request: #{snip data}"
        stream.on 'data', (data) -> debugData chalk.grey "received #{snip data}"
        sock.pipe(stream).pipe sock
    tunnel.on 'close', ->
      debug chalk.grey "closing tunnel to #{name}"
      delete conn.tunnel[name]
      unless conn.tunnel.length
        conn.end()
    tunnel.setup =
      host: setup.localHost
      port: setup.localPort
    conn.tunnel[name] = tunnel
    # return running tunnel
    tunnel.listen setup.localPort, ->
      cb null, tunnel

findPort = (setup, cb) ->
  return cb null, setup if setup.localPort
  portfinder.getPort (err, port) ->
    return cb err if err
    setup.localPort = port
    return cb null, setup


# General setup
# -------------------------------------------------

# Class definition
# -------------------------------------------------
class Tunnel

  # create a new execution object to specify and call later
  constructor: (@setup) ->

  close: (cb) ->
