# note that we used the command #puppet agent -t --environment=advanced to deploy the 'advanced' environment configuration instead of the default 'production' environment
node 'master.puppet.vm' {
  include role::master
  file {'/etc/secret_password.txt':
    ensure => file,
    content => lookup('secret_password'),
  }
}

node 'db.puppet.vm' {
  include role::elk
}

node 'microk8s.puppet.vm' {
  include role::microk8s
}
