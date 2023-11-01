# this class is for creating a webhook that auto pulles repo changes on master server so we don't have to pull the changes manually with "r10k deploy environment -p" command
class profile::r10k {
  #below we are using some classes from the r10k module
  class {'r10k':
    remote => 'https://github.com/BasharDlaleh/puppet_control_repo',
  }
#  class {'r10k::webhook::config':
#    use_mcollective => false,
#  }
  #because this is an open source server, there's two parameters required here, user root and group root
  class {'r10k::webhook':
    user  => 'root',
    group => 'root',
    tls    => {
      enabled     => false,
  },
  }
}
