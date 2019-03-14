require 'puppet/resource_api'

Puppet::ResourceApi.register_transport(
  name: 'panos',
  desc: <<-EOS,
This transport connects to Palo Alto Firewalls using their HTTP XML API.
EOS
  features: [],
  connection_info: {
    host: {
      type: 'String',
      desc: 'The FQDN or IP address of the firewall to connect to.',
    },
    port: {
      type: 'Optional[Integer]',
      desc: 'The port of the firewall to connect to.',
    },
    user: {
      type: 'Optional[String]',
      desc: 'The username to use for authenticating all connections to the firewall. Only one of `username`/`password` or `apikey` can be specified.',
    },
    password: {
      type: 'Optional[String]',
      sensitive: true,
      desc: 'The password to use for authenticating all connections to the firewall. Only one of `username`/`password` or `apikey` can be specified.',
    },
    apikey: {
      type: 'Optional[String]',
      sensitive: true,
      desc: <<-EOS,
The API key to use for authenticating all connections to the firewall.
Only one of `user`/`password` or `apikey` can be specified.
Using the API key is preferred, because it avoids storing a password
in the clear, and is easily revoked by changing the password on the associated user.
EOS
    },
    ssl: {
      type: 'Optional[Boolean]',
      desc: 'Weither to use SSL verification. By default it is turned on, to turn it off specify false.',
    },
    ssl_ca_file: {
      type: 'Optional[String]',
      desc: <<-EOS,
The full path to a CA certificate in PEM format. The certificate of the target needs to be signed by this CA.
The file needs to exist on the proxy agent's local file system. Only one of `ssl.ca_file` and `ssl.fingerprint` can be provided.

Example: `'/etc/ssl/certs/Go_Daddy_Root_Certificate_Authority_-_G2.pem'`.

Alternatively it will use the certs in `OpenSSL::X509::DEFAULT_CERT_FILE`, e.g.:

`ruby -ropenssl -e 'puts OpenSSL::X509::DEFAULT_CERT_FILE'` if no `ssl.ca_file` is provided
EOS
    },
    ssl_version: {
      type: 'Optional[Enum["TLSv1", "TLSv1_1", "TLSv1_2", "SSLv23"]]',
      desc: 'The SSL version to use, refer to the OpenSSL docs (https://www.openssl.org/docs/man1.1.1/man3/SSL_version.html) for more information.',
    },
    ssl_ciphers: {
      type: 'Optional[Array]',
      desc:  <<-EOS,
An array specifying the allowed ciphers for the connection.

A list of supported ciphers can be displayed by executing `ruby -ropenssl -e 'puts  OpenSSL::Cipher.ciphers'`.

For more details refer to the OpenSSL docs on ciphers (https://www.openssl.org/docs/man1.0.2/man1/ciphers.html).
EOS
    },
    ssl_fingerprint: {
      type: 'Optional[String]',
      sensitive: true,
      desc:  <<-EOS,
A string specifying the SHA256 fingerprint of the firewall's certificate in hex notation.

This can be generated by `openssl x509 -sha256 -fingerprint -noout -in cert.pem` or seen in your browser's SSL certificate information.

Only one of `ssl_ca_file` and `ssl_fingerprint` can be provided. Example: `'9A:6E:C0:12:E1:A7:DA:9D:BE:34:19:4D:47:8A:D7:C0:DB:18:22:FB:07:1D:F1:29:81:49:6E:D1:04:38:41:13'`
EOS
    },
  },
)