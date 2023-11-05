# control-repo

## Exec Resource Note
exec resource type is used to run a command or a script on the agent nodes and is often miss-used because most people use it to run a procedural script just like programming languages but Puppet is more about manging the desired state so when we use exec we need to think about the state we want and what if that state is already met. so it's better to take that into consideration when writing scripts to be run by the exec resource.

## Namevar parameter
in Puppet all resources have a Namevar parameter which for example is the path of the file in case of file resource, it's sometimes better and cleaner to write the path of the file/directory in the Namevar parameter instead of wriitng it with the file name in the title
```
file {'file_name'
  path => '/var/www'
}
```
## CLasses
classes are not like programming languges classes, they are just a way to organize puppet code and make it reusable by defininf a group of resources in the class, you can use the classes you define in 2 ways:
1. like other resources in case you wanted to override any variables the class exposes:
class {'class_name':
  parameter1 => 'value1',
}
2. with the include keyword:
include class_name

when we add profile::class1 before the class name it means we're adding this class the profile module scope, we can add classes under nested scopes like profile::system::class1 

### Classes Inhertiance
it's possible to inherit classes in Puppet but it's not recommended except for a params class
```
class profile::class1(
  #here we add exposed variables, the type is optional
  String var1='value1'
) inherits profile::params{
  #here we add resources
}
```
a params class is class we use to pass different values based on something like a fact sent from the agent node, below we're using the osfamily fact that's received from the agent node Facter to decide what to name the admin user we will create based on the OS and we're throwing an error in case the OS is not in the list
```
class profile::params {
  case $::osfamily {
    'Windows': {
      $admin_user = 'Administrator'
    }
    'RedHat': {
      $admin_user = 'root'
    }
    default: {
      fail('os not supported')
    }
  }
}
```
## Puppet Graph
Puppet uses a Direct Acyclic Graph (DAG) to represent your code, DAG is how Puppet thinks about your infrastructure. When your code is compiled, Puppet builds a model of your infrastructure in the form of a DAG.
You can use before/require/notify/subscribe to implement the relationships and dependecies between your resources
before: means to run this resource before the specified resource
require: means to run the required resources before this resource (same as before but reversed)
notify: used to trigger another resource when this resource is changed (like restarting NGINX after a config file change)
subscribe: used to trigger this resource when another resource is changed (same as notify but in reverse)

we can go to validate.puppet.com to validate our code and show a relationship/dependcy graph for our resources.

## Custom Resource Types
Often, you'll create a custom defined resource type, when you have a class or a section of code that you wanna repeat multiple times. You could use an iterator for this, But defined types offer some abstraction and can make your code much more readable. an example of a class that we may want to turn into a defined type is a class that creates an admin user and adds their public access key so that they can log in securely. But because it's a class, we can only use it once. The only change you need to make in this example to convert it to a defined type is to change the word class to define.
```
define admin_user (
  $username = 'root',
  $email    = 'root@localhost',
  $pubkey
){
  user { $username:
    ensure => present,
  }

  ssh_authorized_key{ $email:
    ensure => present,
    user   => $username,
    type   => 'ssh-rsa',
    key    => $pubkey,
  }
}

then you can use it just like any built-in type:

admin_user{ 'bashar':
  username => 'bashar',
  pubkey   => 'AAATR6gvjUURYBJKEEKDJKJDLJDLEJIHLSLSSLSMJLKDLDHFJKSHJHDSJDSHDLSKDLSJDKL'
}
```
## Variables
variables in Puppet are similar to oany prograaming language with the exception that they are immutable, meaning you can't change a variable after you assign a value to it. which makes sense because it's a cnofiguration managment tool that compiles your code and the agent facts to make a catalog so it doesn't make sense to hange a variable while creatin the catalog.

$name = 'bashar'                             ======> use single quotes for normal string
$full_name = "fullname is ${name} Dlaleh"    ======> use double quotes for interpolation 
$status = true
$count = 3
$arr = [1, 2, 'bashar', $full_name]
$hash = { $name = 'bashar', $age = 30}

arrays can be used to iterate on a resource instead of writing the same resource type many times.

# Conditions

### IF
if condition will be true if the condition result is not empty and false if the result is empty, any non-empty result will be true even if it's "false"
```
if $some_boolean {
  include class1
}else {
  include class1
}
```
### UNLESS
unless is the reverse of if
```
unless $some_number > 10 {
  include class1
}else {
  include class1
}
```
### CASE
case statement is shorter for multiple if statements
```
Case $employee_name {
  'bob': { include easy_tools }
  'carol', 'ahmed': { include expert_tools }
  'bashar': { include regular_tools }
}
```
### SELECTOR
Selector statement is similar to Case but is only used for assiging values based on a condition (case can be used)
below we're evaluating the os_family fact sent from the agent to choose what text editor to istall (of course the condition doesn't have to be a fact)
```
$default_editor $employee_name = $facts['os']['family'] ? {
  'Linux'   => 'vim'
  'Windows' => 'notepad'
  default   => 'nano'       ==> default value
}
```
## Iteration

we can use 'each' to loop on an array or a hash (a hash is like a dictionary in python):
```
['ali', 'bob', 'carol'].each |$username| {
  user {$username:
    ensure => present,
  }
}
```
in the above example we don't need an iterator we can just use an array whic is simpler:
```
user {['ali', 'bob', 'carol']:
  ensure => present,
}
```
however, each iterator is useful when we wannt iterate over a variable instead of static value:
```
['ali', 'bob', 'carol'].each |$username| {
  user {$username:
    home => "/var/www/$username",
  }
}

{
  'ali'   => '/var/www/ali'
  'bob' => '/var/www/bob_web'
  'carol'   => '/var/www/carol_secret'       
}.each |$username, $homedir| {
  user {$username:
    home       => $homedir,
    managehome => true
  }
}
```
we can achieve the above without iterators and just by using a defined custom resource (it's up to you to choose the better way for your case but since a custom resource defines an additonal layer of abstraction it's better to use it for more complex cases where you need to define more than 3 resources):
```
define webuser (
  $username
){
  user {$username:
    home => "/var/www/$username",
  }
}

webuser {['ali', 'bob', 'carol']:
  ensure => present,
}
```
note that there are other functions to iterate like .map and .filter which are similar to Javascript use cases

## Facts

facts are collected by Facter on agent nodes and sent to Puppet master server, you can use agent facts to decide what config to apply to them, we have 2 ways to access facts in Puppet code:

1. using $ like any other local variable (we add :: before the fact name to ditinguish it from local variables but it's not mandatory):

$operatingsystemmajorrelease
$::operatingsystemmajorrelease

2. using the facts has (this way is absolutley better and easier to read):

$facts['os']['release']['major']

a common use of facts is to decide what values to use based on operating system type which is used a lot in params class:

``
case $facts['os']['name'] {
  'Solaris': { include role::solaris}
  'RedHat', 'CentOS': { include role::redhat}
  /^(Debian|Ubuntu)$/: { include role::debian}
  default: fail('unsupported operating system')
}
``
## Functions

Puppet has many built-in functions to make your life easy like 
- each() for iteating on items.

- fail() to fail with a specific message which very useful because it fails in compile time on the master rather than failing in the agent node itself.

- epp() which is used with templates where we pass the template name and the values we wanna add in that template and it returns a string that contains the entire interpreted template with the values you want.

- lookup() is used to retrieve data from 'Heira' which is a hierarical key-value data store that comes with Puppet, below we're retrieving the users list from Heira by passing the admin_users key:
```
$userlist = lookup('profile::$admin_users::users')

user {$userlist:
  ensure => present,
}
```
Heira and the lookup function here do the complicated work of figuring out which list of users should be returned for that particular node, which helps keep your puppet code simple and readable.

## File Sources

we can use the puppet file serving system to serve files from some directory on the puppet master:
```
file {'/etc/motd':
  ensure  => file,
  source => 'puppet:///modules/modulename/directory/motd.txt',
}
```
we can use an external server to serve files instead of the master server by specifying the server (ip or dns) and the mount_path(modulename) and finally the path to the file (note that this solution has been deprecated and now there are other better options to host files):

puppet://<SERVER>/<MOUNT PATH>/<PATH>

## Resource Default

Resource defaults are used if you're defining multiple resources in a class, and you want them all to have the same setting for one of the perameters, you don't need to type it multiple times. Instead, you can use a capital letter for the start of the resource type name and it will apply to all resources within the local scope. For now, just think of a scope as resources defined within the same class.
the below owner, group, mode parameters will be applied to all file resources:
```
File {
  owner => 'root',
  group => 'root',
  mode => '0644',
}

file {'/etc/profile':
  ensure  => file,
  source => 'puppet:///modules/defaults/profile.txt',
}

file {'/etc/motd':
  ensure  => file,
  source => 'puppet:///modules/defaults/motd.txt',
}
```
Here's another way of specifying defaults for several files. It's less common than the one above, but in many ways, it's the better method because it doesn't run into any tricky issues with scope (the defaults will only apply to the resources defined under it). In this method, the resource defaults are limited to these resources. There are two new things in this style. First, there's the default section at the top. The other difference is that each section is separated by a semicolon
```
file {
  default:
    owner => 'root',
    group => 'root',
    mode => '0644'
  ;
  '/etc/profile':
    ensure  => file,
    source => 'puppet:///modules/defaults/profile.txt',
  ;
  '/etc/motd':
  ensure  => file,
  source => 'puppet:///modules/defaults/motd.txt',
}
```
## r10k 

r10k is used to deploy pupper repo changes, we can add r10k in 2 way:
1. install it with gem and configure it manually (like we did in the Beginner's course)
    #gem install r10k
    #mkdir /etc/puppetlabs/r10k
    #vim /etc/puppetlabs/r10k/r10k.yaml
2. use puppet to install r10k as a module and confgure it automatically with one command
    #puppet module install puppet/r10k --modulepath=/etc/puppetlabs/code/modules/
    #puppet apply -e 'class {"r10k": remote => "https://github.com/BasharDlaleh/advanced_puppet_control_repo.git"}' --modulepath=/etc/puppetlabs/code/modules/

and then we can start running #r10k deploy environment -p

r10k and a control repo adds a powerful feature called code environments to Puppet. This lets you segment your infrastructure by environment and have separate branches in your control repo code so that each environment has its own configuration (r10k instantiates an environment per branch in /etc/puppetlabs/code/environments). When a node checks in with the master, it will determine the appropriate environment for that node and then compile the catalog for that node using the code for that specific environment. Code environments can map to your actual infrastructure environments like Dev-QA-Prod or QA-Staging-Prod.

## Hiera (hierarchy)
```
user {['bob', 'carol', 'bashar']:
  ensure => present,
}
```
above creating three user accounts. imagine instead of three users, you have 30 or 300. What looks like reasonable code suddenly seems insane. Instead of including data like a list of users in the code, we can use a tool called Hiera to extract that away. This lets us focus on what our Puppet code does, and not get polluted by mixing data in with the code. the look up function needs to get the data from somewhere. Hiera is a tool that comes with Puppet. Its name come from the word hierarchy. Hiera works by allowing you to set up a hierarchical look up for your data. So that the more specific data can override the general.

                                         DataCenters
                                      Nodes
                                        Environments
                                     Default

Imagine that this is the default settings that you'd like for most of your infrastructure. Default packages, add new users, that kind of thing. Then, above that, you had a layer for the environments. So in the Dav environment you might want to have debugging tools installed. And in Prod, you don't want the developers to have Sudu access. In the layer above, you might have some data that applies to specific nodes, or maybe different settings for different data centers. Imagine that look up function as looking from the top down on this stack. It will only see what's on the very top, so it will override the layers below. That's the hierarchy.

#### Hiera Backends

we have many options to use as Hiera backend for storing data: 

1. store in plain yaml files (which is not secure)
2. use a database 
3. use eyaml which is encrypted-yaml where you can use yaml files and encrypt them instead of leaving them as plaintext



#### Install EYAML

we need to use gem to install eyaml, note that the gem version installed on your master node isn't the same as the one that puppet master has built-in inside the java jvm (because Puppet Server is a Ruby application that runs on the Java Virtual Machine JVM) so they maybe be different versions, to use eyaml we need to install hiera-eyaml gem on both the host and the puppetserver:

#gem install hiera-eyaml                 ===> on host
#puppetserver gem install hiera-eyaml    ===> on puppet server

after that we need to create eyaml keys to use them for encryption:

#cd /etc/puppetlabs/puppet
#eyaml createkeys                         =====> will create keys in a directory named keys
#mv keys/ eyaml-keys/                     =====> we can rename the folder to make it more clear
#chown -R puppet:puppet /etc/puppetlabs/puppet/eyaml-keys/     =====> secure the folder
#chmod -R 0500 /etc/puppetlabs/puppet/eyaml-keys/              =====> secure the folder
#chmod -R 0400 /etc/puppetlabs/puppet/eyaml-keys/*.pem         =====> secure the keys

now we need to add hiera.yaml config file to the repo to tell hiera what we want to do (define the hierarchy and the paths to the keys).
note that:
1. we created an encrypted data file with the comamnd  #eyaml edit common.yaml on the master server whic has the eyaml keys.
2. we added the genrated file commom.yaml in the repo under data directory.
3. puled the code on master with r10k, the master knows how to decrypt it because it has the keys in which it were encrypted.
4. when an agent asks for configuration the master decrypts the encrypted files and compile it in the catalog and send it to the agents.

####################################################################################################################################
note that we used the command #puppet agent -t --environment=advanced to deploy the 'advanced' environment configuration instead of the default 'production' environment instead of creating a new VM for the advanced course
####################################################################################################################################

## Testing

puppet testing is done in three layers from top to bottom:

1. syntax checking and linting: There's a handy tool called puppet-lint that you can download as a gem. It will catch outright syntax errors and typos, but it also gives a lot of suggestions for improving the style of your Puppet code to make it more readable. 

#puppet parser validate example.pp
#puppet-lint example.pp

2. unit and integration tests: Usually unit tests refer to small tests that work on a single unit of code, for example, an object class or even a single function. Integration tests tend to be more about putting the pieces together. With Puppet, we use a same tool for both tasks whihc is puppet-rspec. Puppet-rspec is also available as a gem.

3. automated acceptance tests and manual tests: Acceptance tests actually try out the code on some kind of simulated environment. There's a tool called beaker that's used to test Puppet itself, that can be used for this purpose. But it's also possible to use Vagrant as a test environment, or even use Packer. Beaker is nice because it lets you do multi-node testing. the manual tests is where you just manually set up a VM and apply your Puppet code. There's a reason these are at the bottom. They're the most resource, time, and labor intensive of the tests. So you wanna catch the simple bugs before you get to this layer.

here we actually write a vagrant file that provisions a vm and runs a script that applies puppet config and then use a tool like RSPEC-PUPPET to make sure the config are applied.

#### RSPEC_PUPPET

RSPEC-PUPPET is the tool for testing your puppet code. It's based on rspec, which is a ruby testing tool. Rspec and Rspec-puppet have their own domain specific language DSL for creating tests. It's fairly straightforward and you'll find that a lot of the tests follow a very similar pattern

install rspec-puppet and some helpers:

#gem install rspec-puppet puppetlabs_spec_helper rspec-puppet-facts

the puppet development kit PDK is a tool that we can use for developing modules, but it also has a handy feature of generating tests as you are working on your module, we can either install the GUI app on our laptop just like VSCode or install the CLI tool on a dev server which will give us some commands to make building modules and tests easy

#cd site/
#pdk new module rspec_example ===> will generate a base module files and directories including an spec folder which includes the tests
#cd rspec_example             
#pdk new class rspec_example  ===> will generate an init class for the module in module_name/manifests/init.pp 
#cd rspec_example/spec/classes
#rspec                        ===> will run the generated tests in spec folder

Running rspec directly isn't really recommended. It's actually better to use the rake command. Rake is a Ruby build tool that allows you to configure various tasks associated with your code, like packaging the module to be uploaded to the Puppet Forge, or running these rspec tests. It uses a rake file for configuration, and, in the case of the generated code, it has a number of built-in tasks.

#rake spec     ===> same as rspec
#rake lini     ===> same as puppet-lint

The default test that's generated by the PDK is to check if the module compiles without errors, and the PDK has the handy feature of generating tests for every operating system that your module supports. So you can see that our class will compile on all these Debian family operating systems(because we chose Debian only). the test file is spec/classes/rspect_example_spec.rb. 
```
#This first line means that it's importing code from another helper file
#the code describes the class name and loops through a list of supported operating systems.
require 'spec_helper'

describe 'rspec_example' do
  on_supported_os.each do |os, os_facts|

    #The context block here lets you create multiple subsections in your test. In this case, it's one for each of the operating systems.
    context "on #{os}" do
  
    #The let facts line allows us to set facts that Puppet would use when compiling the catalog. This is important, because rspec doesn't gather facts using facter, if your code depends on certain facts, you'll need to specify them so the master gets them for you.
      let(:facts) { os_facts }
  
      #this is the heart of the test. For every operating system, the class should compile. it gets the list of operating systems from the helper scripts, which parse the metadata.json file in the root of the module.
      it { is_expected.to compile.with_all_deps }
  
    end
  end
end
```
RSPEC is a big thing so you need to take a course on it.

we can integrate any module we build with Travis-ci to have automated runs for the tests we have by creating a git repo and pushing the module code to it.

#### Beaker

we sat up beaker but didn't really make it work because it needs to be run on our host machine and provision vagrant vms which requires installing a lot of things on the host (ruby, gems, .....etc)

## Modules 

A Puppet module is really just a structured set of directories and text files organized and named in a way that Puppet expects. the main files and directories that you'll find in a module:

1. The manifests directory: is where Puppet code goes, and it needs to follow a specific structure. For example, here's the code for an Apache class in the main Puppetlabs Apache module. For the main class in the module, that is, the one that shares a name with the module, the code goes in manifests/init.pp. For the rest of the code in the module, the pattern is simpler. For the Apache proxy class, for example, the code belongs in manifests/proxy.pp, and for classes or defined types that are similar to the pattern apache::mod::python, the code would go into a subdirectory at the manifests directory, manifests/mod/python.pp. It's also worth noting here that the apache::mod defined type goes in manifests/mod.pp, even though we already have a directory named manifests/mod. 

2. The files directory: is where you put any files that are always the same, that is, files that don't need to adapt to the specifics of the node where the code is applied. 

3. The templates directory: holds all your dynamic templates, text files that include variables from your Puppet code. When writing a module, we start with a lot of static files and then end up converting them to templates as the code gets more complex.

4. The spec directory: holds things like unit and acceptance test code and supporting files. Some tests will look for a subdirectory called spec/fixtures, which holds the supporting code for your tests, such as dependency modules. Those modules are specified in a .fixtures.yml file in the root directory of your module. below is an example of a fixtures.yml file from a Graphana module. The makers of Puppet provide a gem called puppetlabs_spec_helper that includes rate tasks and helper scripts for testing your code. One of the features of that gem is downloading fixtures based on this format. You can include remote modules from the forge or source control repositories and local modules using that sim like section. 

5. metadata.json file: This is the file that Puppet and the Puppet Forge use to get the general metadata about the module, such as module dependencies. It's not strictly required, but you'll need it if you're going to push modules to the forge. 

6. the tasks directory: some modules have a tasks directory to support the Puppet tasks feature, which is a way of running ad hoc tests against Puppet nodes rather than managing the desired state. if you're currently using or considering something like Ansible alongside Puppet, you might look into tasks, because they fill a similar function.

in puppet forge website there are a lot of types of modules (supprted, approved, partner, tasks), tasks allow you to perform ad-hoc actions using a tool called Puppet Bolt or the Puppet Enterprise Orchestrator features. For example, the Postgres module has a task that let's you run database queries. Tasks have a lot of potential but it's actually simpler to just use something like SSH.

metda.json
manifests/
          init.pp
          proxy.pp
          mod.pp
          mod/
             python.pp
files/
      static_file.txt
template/
        dynamic_file.epp
spec/
     spec_helper.rb
     classes/
            test.pp

## ELK Module

we created a module that installs ELK stack on agent, note that we had to fix the modules versions one by one and ead the docs to see how to provision a basic elasticsearch instance with kibana and filebeat

we developed our module locally and pushed it to a separate repo, then in the puppet advanced control repo we added the 'elk' module in the Puppetfile to be pulled from git instead of puppet forge

## Reporting

Puppet store reports about its execution in yaml files in a directory we can specify (by default it's /opt/puppetlabs/puppet/cache/state/), the reports of each node will be on the node itself, to show a list of Puppet config:

#puppet config print                      ===> show all config
#puppet config print [config_name]        ===> show one specific config

yaml file reports are not super human-readable, but it's not terrible. You can see what resources changed. You can see some notice resources that happened in this last Puppet run. You can see the total number of what changed. you can see that a resource was out of sync in that Puppet run. You can see whether it was a corrective change or whether it was an intentional change. For each of resources, we can see all the details of what happened. We also see the evaluation time which is a very useful piece of information, because it tells you how long this actually took. So you can look for these in your Puppet code and figure out where the slow points are. It's a great way to improve the speed of your Puppet runs.

The other built-in reporting process apart from the regular log files is the HTTP report processor, which enables you to configure an HTTP server to post these YAML report files to. All the external reporting systems rely on having Puppet DB configured, which is simple to set up. There's a Puppet module for setting up Puppet DB, we add the modules and its dependencies in the Puppetfile,

after that we can create a profile and role for that and add it to the master node (we assume that we want to add the db on the master node itself which is not recommended for production, in production you better add an external db server), also we need to add the db config in puppet.conf file:

1. add puppetdb module and its dependencies in Puppetfile
2. add profile and role to master
3. #puppet agent -t (on master)   ===> this will install puppetdb on master
4. #vim /etc/puppetlabs/puppet/puppet.conf   ===> this will will start using puppetdb for reporting
   [main]
   reports = store, puppetdb, http
5. #systemctl restart puppetserver

#### Configuring Puppetserver to send logs to ELK stack

we will configure puppet master to generate JSON logs and send them to the ELK stack we provisioned on the agent, we'll install filebeat on puppet master and have ship the logs to logstash on the agent,

1. vim /etc/puppetlabs/puppetserver/logback.xml

add a new appender XML tag called JSON to export puppetserver logs and add it to the appevder-ref section at the bottom

2. vim /etc/puppetlabs/puppetserver/request-logging.xml

add a new appender XML tag called JSON to export puppetserver access logs and add it to the appevder-ref section at the bottom

3.  run 'systemctl restart puppetserver.service' so the puppet master will start generating JSON logs

4. first we add prospectors in filebeat config template 'filebeat.yaml.epp' that's used by the filebeat class in the elk module we created so we can configure what logs to ship to elk using prospectors, then we will create a profile filebeat_puppeterver and use the filebeat class in it (will pass the logs we want) and add it to the master role so filebeat service gets installed on the master. 

5. #puppet agent -t (on master)   ===> this will install filebeat on master and configure it to start sending logs to elk.

## Exported Resources

Puppet has a powerful feature called exported resources that allow using information about one node in the config for another. a typical problem that you'd solve with exported resources is a load balancing proxy server. Imagine you are managing a load balancer and a handful of web servers. Setting up the web servers is straightforward with Puppet. You spin up a new instance and add the right role class and run Puppet. Once Puppet is run, you have a new web server ready to go. Let's add a load balancer to the mix. The load balancer needs to know the names or addresses of the active web servers in order to properly route traffic. But how does it find out the address of the new instance? how does it find out those addresses in the first place? With exported resources, we actually define the load balancer config right alongside the web server config so that it will have all the local variables of that web server, like the IP address and name. When Puppet runs on the web server, that bit of load balancer config is exported, below is an example of how that config might look, Imagine that there was a load balancer that would direct traffic to any IP address that's listed in a file inside its config directory. So normally you'd just add a file for each of your instances with its address. Here we'd put this in the Puppet code for the web server basically saying set up a web server and also set up this load balancer config on a different node (That tag parameter is so that we'll be able to find this resource later)

- in the web server config:
```
@@ file {"/etc/loadbalancer/servers/${hostname}.conf":
     ensure => file,
     content => $ipaddress,
     tag => 'lb-config'
}
```
Later, when we run Puppet on the load balancer, we can collect that code and apply it to the load balancer. Then the load balancer will have the address of the web server so that it can start routing traffic there. In fact, if we create multiple web nodes, Puppet will collect all of the load balancer configs onto the load balancer. It's easier to think of this as say the web server exporting its address and the load balancer collecting it, but in reality all of this is happening inside the Puppet master in PuppetDB. The individual web nodes aren't really doing anything related to the exported resource, but it helps to pretend that they are because that's how the Puppet code is set up. Below is what we add to the code that applies to the load balancer itself. There are a few options for how this works. You don't need to use tags. For example, if we left a tag out, it would try to collect every exported resource file in our entire infrastructure. Or if we had a module that had a load balancer member class we could probably just collect all of those without using a tag.

- in the load balancer server config:
`File <<| tag == 'lb-config' |>>`

## Types and Providers

So far we've been using defined resource types and classes, which really provide a lot of functionality. In this lesson, we'll be looking at the layer below that, the system that actually provides the built-in resource types used by Puppet. There are two parts to a resource. First, there is the type definition. This is the file that describes the properties of the resource. What parameters it takes, et cetera. Second, a resource has one or more providers. A provider is what connects the abstract type to the real implementation. It's possible to have multiple providers for a single type, because each provider works for a different operating system. For example, the commands and system calls to create a directory in Windows are different than in Linux. So, even though there's one type for defining a file, there are multiple providers to create that file on the operating system. One nice thing about Puppet types and providers is that you can actually look at the code that Puppet uses for the built-in types. I think the simplest way to do this is to install the Puppet gem. Where the gem is installed will vary by operating systems. Just type gem env, and start digging around in the directory, or directories, listed under gempaths. Once you find the Puppet gem, you'll find the type and provider source code under lib/puppet/type, and lib/puppet/provider.
At a basic level, this is how all providers work. They're what translate the abstract Puppet code into things like actual commands or files. Sometimes they literally wrap a command line command.

Modules often have custom types and providers. They can be added by putting them in lib/puppet/type and lib/puppet/provider, in the root of the module.

## Custom Facts

Puppet supports the ability to add custom facts to your nodes. Customs facts are another advanced Puppet feature you'll commonly see in modules. Just like built-in facts like OS family or IP address, it's possible to create your own facts that interact with the agent node. Remember Puppet code itself runs on the master, so any data about the target system needs to be provided to the master via facts. 
Some of the ways you can create and use custom facts in your own code:

1. Adding a custom fact to your module is pretty simple. You just need to create a directory lib/facter and then a .rb file with the same name as your fact. Inside of that file you'll need some Ruby code. Here's an example from the Puppet documentation. The first line adds a new facter called the hardware_platform and then opens a code block. Under that there's a setcode statement that begins another code block, and within that block we have our call out to an external program, which is what actually retrieves the fact. In Ruby a block of code will return the value of whatever expression is last, so in this case it's returning the result of that execute method.
```
Facter.add('hardware_platform') do
  setcode do
    Facter.Core.Execution.execute('/bin/uname --hardware-platform')
  end
end
```

2. Creating structured facts is also simple. All you need to do is return an array or hash as a result of the setcode block. In this example we're using a regular expression and scan method to make an array of users. 
```
Facter.add('existing_users') do
  setcode do
    users = Facter.Core.Execution.execute('/usr/bin/getent passwd')
    users.scan(/^[^:]+/)
  end
end
```

3. You can generate custom facts using other facts. In this example we use the custom fact we created above and return the length of the array as a new user_count fact.
```
Facter.add('user_count') do
  setcode do
    Facter.value(:existing_users).length
  end
end
```

4. External facts let you write in any language you like. You just need to supply an executable that returns a string in the format fact name equals fact value. This example is a simple Bash script, but you could use Python or Ruby or even a compiled language like C or Go. 
```
modulename/facts.d/test_fact.sh
#! /bin/bash
echo "test_fact=hello world"
```

5. You can use external facts to provide static data. Facter understands YAML and JSON files. You can also use .txt files that have data in the format fact name equals value.
```
modulename/facts.d/test_facts.yaml
---
first_fact: true
second_fact: 2
third_fact: three

modulename/facts.d/test_facts.txt
---
first_fact=true
second_fact=2
third_fact=three
```






 



 

 