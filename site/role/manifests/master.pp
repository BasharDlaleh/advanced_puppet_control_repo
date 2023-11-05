# note that r10k webhook didn't work because of a dependecy error
class role::master {
  #include profile::r10k
  include profile::puppetdb
  include profile::filebeat_puppetserver
}
