chai = require 'chai'
expect = chai.expect

sshtunnel = require '../../src/index'
Exec = require 'alinex-exec'

describe "forward tunneling", ->

  it "should open/close tunnel", (cb) ->
    @timeout 30000
    sshtunnel
      ssh:
        host: '85.25.98.25'
        port:  22
        username: 'root'
        privateKey: require('fs').readFileSync '/home/alex/.ssh/id_rsa'
        keepaliveInterval: 1000
        debug: true
      tunnel:
        host: '172.30.22.241'
        port: 80
        #localPort: 8080
    , (err, tunnel) ->
      tunnel.close()
      setTimeout cb, 100

  it  "should connect socket through tunnel", (cb) ->
    @timeout 30000
    sshtunnel
      ssh:
        host: '85.25.98.25'
        port:  22
        username: 'root'
        privateKey: require('fs').readFileSync '/home/alex/.ssh/id_rsa'
        keepaliveInterval: 1000
        debug: true
      tunnel:
        host: '172.30.22.241'
        port: 80
        #localPort: 8080
    , (err, tunnel) ->
      Exec.run
        cmd: 'bash'
        args: ['-c', "echo > /dev/tcp/#{tunnel.setup.host}/#{tunnel.setup.port}"]
      , (err, proc) ->
        tunnel.end()
        expect(err, 'ping error').to.not.exist
        cb()

describe.skip "socksv5 proxy", ->

  it "should open/close tunnel", (cb) ->
    @timeout 30000
    sshtunnel
      ssh:
        host: '85.25.98.25'
        port:  22
        username: 'root'
        privateKey: require('fs').readFileSync '/home/alex/.ssh/id_rsa'
        keepaliveInterval: 1000
        debug: true
    , (err, tunnel) ->
      setTimeout ->
        tunnel.close()
        setTimeout cb, 100
      , 10000

