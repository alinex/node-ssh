# Check definitions
# =================================================
# This contains configuration definitions for the
# [alinex-validator](http://alinex.github.io/node-validator).

# SSH Settings
# -------------------------------------------------
exports.ssh = ssh =
  title: "SSH Connection"
  description: "a remote server for ssh tunneling"
  type: 'object'
  entries: [
    type: 'array'
    toArray: true
    entries:
      type: 'object'
      allowedKeys: true
      mandatoryKeys: ['host', 'port']
      keys:
        host:
          title: "Hostname or IP Address"
          description: "the hostname or IP address to connect to"
          type: 'or'
          or: [
            type: 'hostname'
          ,
            type: 'ipaddr'
          ]
        port:
          title: "Port Number"
          description: "the port on which to connect using ssh protocol"
          type: 'port'
          default: 22
        forceIPv4:
          title: "Force to use IPv4"
          description: "a flag to only use resolved IPv4 address for host"
          type: 'boolean'
          optional: true
        forceIPv6:
          title: "Force to use IPv6"
          description: "a flag to only use resolved IPv6 address for host"
          type: 'boolean'
          optional: true
        username:
          title: "Username"
          description: "the username to use for the connection"
          type: 'string'
          optional: true
        passphrase:
          title: "Passphrase"
          description: "the passphrase used to decrypt an encrypted private key"
          type: 'string'
          optional: true
        privateKey:
          title: "Private Key"
          description: "the private key file to use for OpenSSH authentication"
          type: 'string'
          optional: true
        localHostname:
          title: "Local Hostname"
          description: "the host used for hostbased user authentication"
          type: 'string'
          optional: true
        localUsername:
          title: "Local User"
          description: "the username used for hostbased user authentication"
          type: 'string'
          optional: true
        keepaliveInterval:
          title: "Keepalive Interval"
          description: "the interval for the keepalive packets to be send"
          type: 'interval'
          unit: 'ms'
          default: 1000
        keepaliveCountMax:
          title: "Keepalive Tries"
          description: "the number of unanswered SSH-level keepalive packets that can
            be sent to the server before disconnection"
          type: 'integer'
          min: 0
          optional: true
        readyTimeout:
          title: "Ready TImeout"
          description: "the time to wait for the ssh handshake to succeed"
          type: 'interval'
          unit: 'ms'
          default: 20000
        strictVendor:
          title: "Strict Vendor Check"
          description: "a flag to performs a strict server vendor check before sending
            vendor-specific requests, etc."
          type: 'boolean'
          optional: true
        algorithms:
          title: "Algotithms"
          description: "the transport layer algorithms to use"
          type: 'array'
          toArray: true
          entries:
            type: 'string'
            values: ['kex', 'cipher', 'serverHostKey', 'hmac', 'compress']
          optional: true
        compress:
          title: "Compression"
          description: "a flag to enable compression if server supports it or force it"
          type: 'or'
          or: [
            type: 'string'
            values: ['force']
          ,
            type: 'boolean'
          ]
          optional: true
        debug:
          title: "Extended Debug"
          description: "the DEBUG=exec.ssh messages are extended with server communication"
          type: 'boolean'
  ]


# Tunnel Settings
# -------------------------------------------------
exports.tunnel =
  title: "Tunnel Setup"
  description: "the setup of a ssh tunnel"
  type: 'object'
  allowedKeys: true
  mandatoryKeys: ['ssh']
  keys:
    ssh:
      type: 'or'
      or: [
        type: 'string'
        list: '<<<context:///ssh>>>'
      , ssh
      ]
    tunnel:
      title: "Tunnel"
      description: "the connection to tunnel"
      type: 'object'
      allowedKeys: true
      keys:
        host:
          title: "Host"
          description: "the hostname or ip address which to tunnel"
          type: 'or'
          or: [
            type: 'hostname'
          ,
            type: 'ipaddr'
          ]
        port:
          title: "Port"
          description: "port to tunnel"
          type: 'port'
        localhost:
          title: "Local IP"
          description: "the local ip where the tunnel will be setup"
          type: 'ipaddr'
          default: '127.0.0.1'
        localPort:
          title: "Local Port"
          description: "the local port to bind to the tunnel"
          type: 'port'
          default: 8000
      optional: true
    retry:
      type: 'object'
      allowedKeys: true
      keys:
        times:
          title: "Number of Tries"
          description: "the number of times to try to connect"
          type: 'integer'
          min: 0
          optional: true
        intervall:
          title: "Wait between Tries"
          description: "the intervall to wait (in milliseconds) between tries"
          type: 'intervall'
          min: 0
          optional: true
      optional: true
