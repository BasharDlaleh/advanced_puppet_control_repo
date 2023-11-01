node puppet.local {
  include role::master
 # file {'/etc/secret_password.txt':
 #   ensure => file,
 #   content => lookup('secret_password'),
 # }
  file {'/etc/test.txt':
    ensure => file,
    content => 'test file',
  }
}
