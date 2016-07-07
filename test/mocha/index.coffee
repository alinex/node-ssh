chai = require 'chai'
expect = chai.expect
### eslint-env node, mocha ###

sshtunnel = require '../../src/index'
exec = require('child_process').exec
fs = require 'fs'
debug = require('debug') 'test'

config = require 'alinex-config'
sshtunnel.setup ->
  config.pushOrigin
    uri: "#{__dirname}/../data/config/*"

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

    describe "config", ->

      it "should run the selfcheck on the schema", (cb) ->
        validator = require 'alinex-validator'
        schema = require '../../src/configSchema'
        validator.selfcheck schema.ssh, (err) ->
          return cb err if err
          validator.selfcheck schema.tunnel, cb

      it "should initialize config", (cb) ->
        @timeout 4000
        sshtunnel.init (err) ->
          expect(err, 'init error').to.not.exist
          config = require 'alinex-config'
          config.init (err) ->
            expect(err, 'load error').to.not.exist
            expect(config.get '/ssh', 'ssh config').to.exist
            expect(config.get '/tunnel', 'tunnel config').to.exist
            cb()

    describe "problems", ->

      it "should fail on unknown host", (cb) ->
        sshtunnel.open
          ssh:
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
        sshtunnel.open
          ssh:
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
        sshtunnel.open
          ssh:
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
        sshtunnel.open
          ssh:
            host: 'localhost'
            port: 22
            username: 'root'
            privateKey: fs.readFileSync '/home/alex/.ssh/id_rsa'
          tunnel:
            host: '127.0.0.1'
            port: 80
        , (err) ->
          debug err?.message
          expect(err, 'tunnel error').to.exist
          cb()

    describe "forward tunneling", ->

      it "should open/close tunnel", (cb) ->
        sshtunnel.open
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
        sshtunnel.open
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
        sshtunnel.open
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
        sshtunnel.open
          ssh: ssh
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
        sshtunnel.open
          ssh: ssh
        , (err, tunnel) ->
          expect(err, 'tunnel error').to.not.exist
          expect(tunnel, 'tunnel').to.exist
          exec "curl -i --socks5 #{tunnel.setup.host}:#{tunnel.setup.port} google.com"
          , ->
            tunnel.end()
            setTimeout cb, 100

      it "should get webpage through tunnel", (cb) ->
        sshtunnel.open
          ssh: ssh
        , (err, tunnel) ->
          expect(err, 'tunnel error').to.not.exist
          expect(tunnel, 'tunnel').to.exist
          exec "curl -i --socks5 #{tunnel.setup.host}:#{tunnel.setup.port} google.com"
          , (err, out) ->
            tunnel.end()
            expect(err, 'curl error').to.not.exist
            expect(out, 'response').to.exist
            setTimeout cb, 300
