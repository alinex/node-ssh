chai = require 'chai'
expect = chai.expect
### eslint-env node, mocha ###

ssh = require '../../src/index'
exec = require('child_process').exec
fs = require 'fs'
debug = require('debug') 'test'

config = require 'alinex-config'
ssh.setup ->
  config.pushOrigin
    uri: "#{__dirname}/../data/config/*"

  # skip all tests if no correct ssl environment set
  return unless fs.existsSync '/home/alex/.ssh/id_rsa'

  describe "ssh", ->
    @timeout 30000

    server =
      host: '85.25.98.25'
      port: 22
      username: 'root'
      privateKey: fs.readFileSync('/home/alex/.ssh/id_rsa').toString()
      keepaliveInterval: 1000
      readyTimeout: 1000
      debug: true

    describe "config", ->

      it "should run the selfcheck on the schema", (cb) ->
        validator = require 'alinex-validator'
        schema = require '../../src/configSchema'
        validator.selfcheck schema, cb

      it "should initialize config", (cb) ->
        @timeout 4000
        ssh.init (err) ->
          expect(err, 'init error').to.not.exist
          config = require 'alinex-config'
          config.init (err) ->
            expect(err, 'load error').to.not.exist
            expect(config.get '/ssh', 'ssh config').to.exist
            expect(config.get '/ssh/tunnel', 'tunnel config').to.exist
            cb()

    describe.only "connect", ->

      it "should work with object", (cb) ->
        ssh.connect
          server: server
        , (err, conn) ->
          console.log conn
          expect(err, 'error').to.not.exist
          expect(conn, 'conn').to.exist
          conn.close()
          cb()

      it "should work with config reference", (cb) ->
        ssh.connect 'testWithKey', (err, conn) ->
          expect(err, 'error').to.not.exist
          expect(conn, 'conn').to.exist
          conn.close()
          cb()

    describe "problems", ->

      it "should fail on unknown host", (cb) ->
        ssh.connect
          server:
            host: 'a-nonexistent-host.anywhere'
            port: 22
          tunnel:
            host: '127.0.0.1'
            port: 80
          retry:
            times: 3
        , (err) ->
          debug err?.message
          expect(err, 'tunnel error').to.exist
          cb()

      it "should fail on wrong port", (cb) ->
        ssh.connect
          server:
            host: 'localhost'
            port: 60022
            username: 'root'
          tunnel:
            host: '127.0.0.1'
            port: 80
        , (err) ->
          debug err?.message
          expect(err, 'tunnel error').to.exist
          cb()

      it "should fail on wrong password", (cb) ->
        ssh.connect
          server:
            host: 'localhost'
            port: 22
            username: 'alex'
            password: 'thisiswroong'
          tunnel:
            host: '127.0.0.1'
            port: 80
        , (err) ->
          debug err?.message
          expect(err, 'tunnel error').to.exist
          cb()

      it "should fail on wrong privateKey", (cb) ->
        ssh.connect
          server:
            host: 'localhost'
            port: 22
            username: 'root'
            privateKey: fs.readFileSync('/home/alex/.ssh/id_rsa').toString()
          tunnel:
            host: '127.0.0.1'
            port: 80
        , (err) ->
          debug err?.message
          expect(err, 'tunnel error').to.exist
          cb()

    describe "forward tunneling", ->

      it "should open/close tunnel", (cb) ->
        ssh.tunnel
          server: server
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
        ssh.tunnel
          server: [
            host: 'localhost'
            port: 22
            username: 'alex'
            password: 'thisiswroong'
          ,
            server
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
        ssh.tunnel
          server:
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
        ssh.tunnel
          server: server
          tunnel:
            host: '172.30.22.241'
            port: 80
            #localPort: 8080
        , (err, tunnel) ->
          expect(err, 'tunnel error').to.not.exist
          expect(tunnel, 'tunnel').to.exist
          exec "wget -O - http://#{tunnel.setup.host}:#{tunnel.setup.port}", (err, out) ->
            tunnel.end()
            expect(err, 'ping error').to.not.exist
            expect(out.length, 'output size').to.be.above 300
            setTimeout cb, 300

    describe "socksv5 proxy", ->

      it "should open/close tunnel", (cb) ->
        ssh.tunnel
          server: server
        , (err, tunnel) ->
          expect(err, 'tunnel error').to.not.exist
          expect(tunnel, 'tunnel').to.exist
          exec "curl -i --socks5 #{tunnel.setup.host}:#{tunnel.setup.port} google.com"
          , ->
            tunnel.end()
            setTimeout cb, 100

      it "should get webpage through tunnel", (cb) ->
        ssh.tunnel
          server: server
        , (err, tunnel) ->
          expect(err, 'tunnel error').to.not.exist
          expect(tunnel, 'tunnel').to.exist
          exec "curl -i --socks5 #{tunnel.setup.host}:#{tunnel.setup.port} google.com"
          , (err, out) ->
            tunnel.end()
            expect(err, 'curl error').to.not.exist
            expect(out, 'response').to.exist
            setTimeout cb, 300
