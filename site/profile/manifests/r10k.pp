# this class is for creating a webhook that auto pulles repo changes on master server so we don't have to pull the changes manually with "r10k deploy environment -p" command
class profile::r10k {
  #below we are using some classes from the r10k module
  class {'r10k':
    remote => 'https://github.com/BasharDlaleh/advanced_puppet_control_repo',
  }
  class {'r10k::webhook::config':
    use_mcollective => false,
  }
  class {'r10k::webhook':
    tls    => {
      enabled     => false,
  },
  }
}
