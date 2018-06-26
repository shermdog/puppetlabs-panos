require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'panos_admin',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage "administrator" user accounts on Palo Alto devices.
    EOS
  base_xpath: '/config/mgt-config/users',
  features: ['remote_resource'],
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name:        {
      type:      'String',
      desc:      'The username.',
      behaviour: :namevar,
    },
    password_hash:    {
      type:      'Optional[String]',
      desc:      'Provide a password hash.',
      xpath:     'phash/text()',
    },
    client_certificate_only: {
      type:     'Optional[Boolean]',
      desc:     'When set to true, uses `ssh_key` for client access.',
      xpath:    'client-certificate-only/text()',
    },
    ssh_key:    {
      type:      'Optional[String]',
      desc:      'Provide the users public key in plain text',
      xpath:     'public-key/text()',
    },
    role:       {
      type:     'Enum["superuser", "superreader", "devicereader", "custom"]',
      desc:     'Specify the access level for the administrator',
      xpath:    'local-name(permissions/role-based/*[1])',
    },
    role_profile:    {
      type:     'Optional[String]',
      desc:     'Specify the role profile for the user',
      xpath:    'permissions/role-based/custom/profile/text()',
    },
  },
  autobefore: {
    panos_commit: 'commit',
  },
)