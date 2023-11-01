node 'master.advanced.puppet.vm' {
  include role::master
  #file {'/etc/secret_password.txt':
  #  ensure => file,
  #  content => lookup('secret_password'),
  #}
}
