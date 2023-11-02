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

```
case $facts['os']['name'] {
  'Solaris': { include role::solaris}
  'RedHat', 'CentOS': { include role::redhat}
  /^(Debian|Ubuntu)$/: { include role::debian}
  default: fail('unsupported operating system')
}

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

here we actually write a vagrant file that provisions a vm and runs a script that applies puppet condig and then use a tool like RSPEC-PUPPET to make sure the config are applied.

#### RSPEC_PUPPET

RSPEC-PUPPET is the tool for testing your puppet code. It's based on rspec, which is a ruby testing tool. Rspec and Rspec-puppet have their own domain specific language DSL for creating tests. It's fairly straightforward and you'll find that a lot of the tests follow a very similar pattern

install rspec-puppet and some helpers:

#gem install rspec-puppet puppetlabs_spec_helper rspec-puppet-facts

the puppet development kit PDK is a tool that we can use for developing modules, but it also has a handy feature of generating tests as you are working on your module, we can either install the GUI app on our laptop just like VSCode or install the CLI tool on a dev server which will give us some commands to make building modules and tests easy

#cd site/
#pdk new module rspec_example ===> will generate a base module files and directories including an spec folder which includes the tests
#cd rspec_example             
#pdk new class rspec_example  ===> will generate an init class for the module in module_name/manifests/init.pp 
#rspec                        ===> will run the generated tests in spec folder

Running rspec directly isn't really recommended. It's actually better to use the rake command. Rake is a Ruby build tool that allows you to configure various tasks associated with your code, like packaging the module to be uploaded to the Puppet Forge, or running these rspec tests. It uses a rake file for configuration, and, in the case of the generated code, it has a number of built-in tasks.

#rake spec     ===> same as rspec
#rake lini     ===> same as puppet-lint

The default test that's generated by the PDK is to check if the module compiles without errors, and the PDK has the handy feature of generating tests for every operating system that your module supports. So you can see that our class will compile on all these Debian family operating systems(because we chose Debian only). the test file is spec/classes/rspect_example_spec.rb. 

This first line means that it's importing code from another helper file.

the code describes the class name and loops through a list of supported operating systems. 

The context block here lets you create multiple subsections in your test. In this case, it's one for each of the operating systems.

The let facts line allows us to set facts that Puppet would use when compiling the catalog. This is important, because rspec doesn't gather facts using facter, if your code depends on certain facts, you'll need to specify them so the master gets them for you. 

this is the heart of the test. For every operating system, the class should compile. it gets the list of operating systems from the helper scripts, which parse the metadata.json file in the root of the module. 