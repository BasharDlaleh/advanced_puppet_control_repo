# note that r10k webhook didn't work because we used the same master vm from the Beginner course whioch was already configured maually
class role::master {
  #include profile::r10k
  file{'/etc/testo.txt':
   ensure => file,
   contetn => 'tttttttttt',
  }
}
