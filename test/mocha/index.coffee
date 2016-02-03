chai = require 'chai'
expect = chai.expect
### eslint-env node, mocha ###

sshtunnel = require '../../src/index'
Exec = require 'alinex-exec'

ssh =
  host: '85.25.98.25'
  port: 22
  username: 'root'
  privateKey: require('fs').readFileSync '/home/alex/.ssh/id_rsa'
  keepaliveInterval: 1000
  debug: true

describe "forward tunneling", ->

  it "should open/close tunnel", (cb) ->
    @timeout 30000
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

  it  "should connect socket through tunnel", (cb) ->
    @timeout 30000
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
    @timeout 30000
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
    @timeout 30000
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
