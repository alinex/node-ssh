chai = require 'chai'
expect = chai.expect
### eslint-env node, mocha ###

sshtunnel = require '../../src/index'
Exec = require 'alinex-exec'
fs = require 'fs'
debug = require('debug') 'test'

describe "sshtunnel", ->
  @timeout 30000
  return @skip() unless fs.existsSync '/home/alex/.ssh/id_rsa'

  ssh =
    host: '85.25.98.25'
    port: 22
    username: 'root'
    privateKey: fs.readFileSync '/home/alex/.ssh/id_rsa'
    keepaliveInterval: 1000
    readyTimeout: 1000
    debug: true

  describe "problems", ->

    it "should fail on unknown host", (cb) ->
      sshtunnel
        ssh:
          host: 'a-nonexistent-host.anywhere'
          port: 22
        tunnel:
          host: '127.0.0.1'
          port: 80
      , (err) ->
        debug err.message
        expect(err, 'tunnel error').to.exist
        cb()

    it "should fail on wrong port", (cb) ->
      sshtunnel
        ssh:
          host: 'localhost'
          port: 60022
          username: 'root'
        tunnel:
          host: '127.0.0.1'
          port: 80
      , (err) ->
        debug err.message
        expect(err, 'tunnel error').to.exist
        cb()

    it "should fail on wrong password", (cb) ->
      sshtunnel
        ssh:
          host: 'localhost'
          port: 22
          username: 'alex'
          password: 'thisiswroong'
        tunnel:
          host: '127.0.0.1'
          port: 80
      , (err) ->
        debug err.message
        expect(err, 'tunnel error').to.exist
        cb()

    it "should fail on wrong privateKey", (cb) ->
      sshtunnel
        ssh:
          host: 'localhost'
          port: 22
          username: 'root'
          privateKey: fs.readFileSync '/home/alex/.ssh/id_rsa'
        tunnel:
          host: '127.0.0.1'
          port: 80
      , (err) ->
        debug err.message
        expect(err, 'tunnel error').to.exist
        cb()

  describe "forward tunneling", ->

    it "should open/close tunnel", (cb) ->
      sshtunnel
        ssh: ssh
        tunnel:
          host: '172.30.22.241'
          port: 80
          #localPort: 8080
      , (err, tunnel) ->
        expect(err, 'tunnel error').to.not.exist
        expect(tunnel, 'tunnel').to.exist
        tunnel.close()
        setTimeout cb, 100

    it "should open/close tunnel (multiple tries)", (cb) ->
      sshtunnel
        ssh: [
          host: 'localhost'
          port: 22
          username: 'alex'
          password: 'thisiswroong'
        ,
          ssh
        ]
        tunnel:
          host: '172.30.22.241'
          port: 80
          #localPort: 8080
      , (err, tunnel) ->
        expect(err, 'tunnel error').to.not.exist
        expect(tunnel, 'tunnel').to.exist
        tunnel.close()
        setTimeout cb, 100

    it "should open/close tunnel (with autodetect key)", (cb) ->
      sshtunnel
        ssh:
          host: '85.25.98.25'
          port: 22
          username: 'root'
        tunnel:
          host: '172.30.22.241'
          port: 80
          #localPort: 8080
      , (err, tunnel) ->
        expect(err, 'tunnel error').to.not.exist
        expect(tunnel, 'tunnel').to.exist
        tunnel.close()
        setTimeout cb, 100

    it  "should connect socket through tunnel", (cb) ->
      sshtunnel
        ssh: ssh
        tunnel:
          host: '172.30.22.241'
          port: 80
          #localPort: 8080
      , (err, tunnel) ->
        expect(err, 'tunnel error').to.not.exist
        expect(tunnel, 'tunnel').to.exist
        Exec.run
          cmd: 'bash'
          args: ['-c', "echo > /dev/tcp/#{tunnel.setup.host}/#{tunnel.setup.port}"]
        , (err) ->
          tunnel.end()
          expect(err, 'ping error').to.not.exist
          setTimeout cb, 300

  describe "socksv5 proxy", ->

    it "should open/close tunnel", (cb) ->
      sshtunnel
        ssh: ssh
      , (err, tunnel) ->
        expect(err, 'tunnel error').to.not.exist
        expect(tunnel, 'tunnel').to.exist
        Exec.run
          cmd: 'curl'
          args: ['-i', '--socks5', "#{tunnel.setup.host}:#{tunnel.setup.port}", 'google.com']
        , ->
          tunnel.end()
          setTimeout cb, 100

    it "should get webpage through tunnel", (cb) ->
      sshtunnel
        ssh: ssh
      , (err, tunnel) ->
        expect(err, 'tunnel error').to.not.exist
        expect(tunnel, 'tunnel').to.exist
        Exec.run
          cmd: 'curl'
          args: ['-i', '--socks5', "#{tunnel.setup.host}:#{tunnel.setup.port}", 'google.com']
        , (err, proc) ->
          tunnel.end()
          expect(err, 'curl error').to.not.exist
          expect(proc.stdout(), 'response').to.exist
          setTimeout cb, 300
