
# SSH Tunneling class
# =================================================
# This is an object oriented implementation around the core `process.spawn`
# command and alternatively ssh connections.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('ssh')
chalk = require 'chalk'
ssh = require 'ssh2'
# include alinex modules
async = require 'alinex-async'


# Instantiation
# -------------------------------------------------
exports.open = open = (setup, cb) ->
  connect setup.ssh, (err, conn) ->
    return cb err if err
    forward conn, setup.tunnel, (err, conn) ->
      return cb err if err
      cb null, tunnel

connections = {}
connect = (setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, connections[name] if connections[name]
  # open new ssh
  conn = {}
  # store connection
  conn.tunnel = {}
  connections[name] = conn
  cb null, conn

forward = (conn, setup, cb) ->
  name = "#{setup.host}:#{setup.port}"
  return cb null, conn.tunnel[name] if conn.tunnel[name]
  # make new tunnel
  localPort = setup.localPort ? find---free---port
  tunnel = {}
  # store tunnel
  conn.tunnel[name] = tunnel
  cb null, tunnel


# General setup
# -------------------------------------------------

# Class definition
# -------------------------------------------------
class Tunnel

  # create a new execution object to specify and call later
  constructor: (@setup) ->

  close: (cb) ->
