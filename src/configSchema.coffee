###
Configuration
===================================================
The configuration is the same for tunneling and remote executions and is defined
in three parts:
###


###
/ssh/server
------------------------------------------------------
This defines the preconfigured server connections which are used as connection
or for tunneling, too. All information like access and authenticate are contained
as an object.

{@schema #keys/server}
###
conn =
  title: "SSH Connection List"
  description: "the list of possible ssh connections, the first working will be used"
  type: 'object'
  entries: [
    title: "SSH Connections"
    description: "a list of ssh connection alternatives"
    type: 'array'
    toArray: true
    shuffle: true
    entries:
      title: "SSH Connection"
      description: "a ssh connection setting"
      type: 'object'
      allowedKeys: true
      mandatoryKeys: ['host', 'port']
      keys:
        host:
          title: "Hostname or IP Address"
          description: "the hostname or IP address to connect to"
          type: 'or'
          or: [
            title: "Hostname"
            description: "the hostname to connect to"
            type: 'hostname'
          ,
            title: "IP Address"
            description: "the IP address to connect to"
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
        password:
          title: "Password"
          description: "the password for user based authentication"
          type: 'string'
          optional: true
        privateKey:
          title: "Private Key"
          description: "the private key file to use for OpenSSH authentication"
          type: 'string'
          optional: true
        passphrase:
          title: "Passphrase"
          description: "the passphrase used to decrypt an encrypted private key"
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
            title: "Algorithm"
            description: "an allowed transport layer algorithm"
            type: 'string'
            values: ['kex', 'cipher', 'serverHostKey', 'hmac', 'compress']
          optional: true
        compress:
          title: "Compression"
          description: "a flag to enable compression if server supports it or force it"
          type: 'or'
          or: [
            title: "Force Compression"
            description: "a setting to force compression use"
            type: 'string'
            values: ['force']
          ,
            title: "Compression Allowed"
            description: "a flag to allow/disallow compression"
            type: 'boolean'
          ]
          optional: true
        debug:
          title: "Extended Debug"
          description: "the DEBUG=exec.ssh messages are extended with server communication"
          type: 'boolean'
          optional: true
  ]

###
/ssh/tunnel
------------------------------------------------------
This defines the tunnel which has to be established on a ssh connection.The remote
server may be given here or a reference name to the previous `server` section.

{@schema #keys/tunnel}
###
tunnel =
  title: "Tunnel Setup List"
  description: "the setup of ssh tunnels"
  type: 'object'
  entries: [
    title: "Tunnel Setup"
    description: "the setup of a ssh tunnel"
    type: 'object'
    allowedKeys: true
    mandatoryKeys: ['remote']
    optional: true
    keys:
      remote:
        title: "SSH Connection"
        description: "the ssh connection to use"
        type: 'or'
        or: [
          title: "SSH Connection Reference"
          description: "the reference name for an defined ssh connection under config '/ssh/NAME'"
          type: 'string'
          list: '<<<data:///ssh/server>>>'
        , conn
        ]
      host:
        title: "Host"
        description: "the hostname or ip address which to tunnel"
        type: 'or'
        or: [
          title: "Hostname"
          description: "the hostname which is tunneled"
          type: 'hostname'
        ,
          title: "IP Address"
          description: "the IP address which is tunneled"
          type: 'ipaddr'
        ]
      port:
        title: "Port"
        description: "port to tunnel"
        type: 'port'
      localHost:
        title: "Local IP"
        description: "the local ip where the tunnel will be setup"
        type: 'ipaddr'
        default: '127.0.0.1'
      localPort:
        title: "Local Port"
        description: "the local port to bind to the tunnel"
        type: 'port'
        default: 8000
  ]


###
/ssh/retry
------------------------------------------------------
The last part `retry` is used to make the connection more stable and allows you to
configure an automatic retry loop while connecting to the remote machine with a short break.

{@schema #keys/retry}
###
retry =
  title: "Retry"
  description: "the handling of retries on connecting"
  type: 'object'
  allowedKeys: true
  keys:
    times:
      title: "Number of Tries"
      description: "the number of times to try to connect"
      type: 'integer'
      min: 0
      optional: true
    interval:
      title: "Wait between Tries"
      description: "the interval to wait (in milliseconds) between tries"
      type: 'interval'
      min: 0
      optional: true
  optional: true


# Complete config
# -----------------------------------------------------------
# All three parts together are exported as the complete configuration structure.
module.exports =
  title: "SSH Settings"
  description: "the SSH connection settings"
  type: 'object'
  keys:
    server: conn
    tunnel: tunnel
    retry: retry
