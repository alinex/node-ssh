chai = require 'chai'
expect = chai.expect

sshtunnel = require '../../src/index'

describe "Base", ->

  describe "config", ->

    it "init tunnel", (cb) ->
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
        console.log '---->', "#{tunnel.setup.host}:#{tunnel.setup.port}", "tunnel open"
        setTimeout ->
          tunnel.close()
          setTimeout cb, 100
        , 10000
