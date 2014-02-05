$ar_databases = ['activerecord_unittest', 'activerecord_unittest2']
$as_vagrant   = 'sudo -u vagrant -H bash -l -c'
$user         = 'vagrant'
$home         = '/home/${vagrant}'
$ruby_version = '2.1.0'


Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin']
}

# --- Preinstall Stage ---------------------------------------------------------

stage { 'preinstall':
  before => Stage['main']
}

class apt_get_update {

  exec { "update_apt-get":
      command => "apt-get -y update"
  }

  package { 'python-software-properties':
    ensure => installed,
    require => Exec['update_apt-get']
  }

  # Allows for installing packaged from SSL repos.
  package { 'apt-transport-https':
    ensure => installed,
    require => Exec['update_apt-get']
  }

  package { 'build-essential':
    ensure => installed,
    require => Exec['update_apt-get']
  }

  package { 'python':
    ensure => installed,
    require => Exec['update_apt-get']
  }

  exec { 'add_node_repo':
    command => 'add-apt-repository ppa:chris-lea/node.js',
    require => Package['python-software-properties']
  }

  exec { 'add_ruby_repo':
    command => 'add-apt-repository ppa:brightbox/ruby-ng',
    require => Package['python-software-properties']
  }

  package { 'curl':
    ensure => latest
  }


  package { 'locales':
    ensure => latest
  }->
  exec{ 'gen_locales':
    command => 'locale-gen en_US en_US.UTF-8',
  }->
  exec{ 'config_locales':
    command => 'dpkg-reconfigure locales',
  }
  exec { 'apt-get -y update':
    #unless => "test -e ${home}/.rvm",
    require => Exec['config_locales']
  }
}
class { 'apt_get_update':
  stage => preinstall
}

# --- SQLite -------------------------------------------------------------------

package { ['sqlite3', 'libsqlite3-dev']:
  ensure => installed;
}

# --- PostgreSQL ---------------------------------------------------------------

class install_postgres {

  $version = '9.1'

  package{["postgresql-$version",'postgresql-contrib','postgresql-common','postgresql-client','libpq-dev']:
    ensure => present,
  }

  exec { "drop_cluster":
    command => "pg_dropcluster --stop $version main"
  }->
  exec { "create_cluster":
    command => "pg_createcluster --start -e UTF-8 $version main"
  }->
  exec { "create_pg_user":
    command => "sudo -u postgres createuser -d -R -w -s rumble",
    # user => "postgres",
  }->
  service { "postgresql":
    name        => 'postgresql',
    enable      => true,
    ensure      => running,
    hasstatus   => false,
    hasrestart  => true,
    provider    => 'debian',
    subscribe   => Package["postgresql-$version"],
  }

  file { "postgresql-server-config-$version":
    name    => "/etc/postgresql/$version/main/postgresql.conf",
    ensure  => present,
    content => template('postgresql/postgresql.conf'),
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0644',
    require => [Package["postgresql-$version"], Exec['create_pg_user']],
    notify  => Service["postgresql"],
  }->
  file { "postgresql-server-hba-config-$version":
    name    => "/etc/postgresql/$version/main/pg_hba.conf",
    ensure  => present,
    content => template('postgresql/pg_hba.conf'),
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0640',
    require => [Package["postgresql-$version"], Exec['create_pg_user']],
    notify  => Service["postgresql"],
  }

}
class { 'install_postgres': }

# --- Memcached ----------------------------------------------------------------

class { 'memcached': }

# --- Packages -----------------------------------------------------------------
class install_packages {
  # Install Ruby dependencies
  package { ['bison', 'openssl', 'libreadline6','libreadline6-dev', 'git', 'git-core',
   'zlib1g', 'zlib1g-dev', 'libssl-dev', 'libyaml-dev', 'libxml2-dev', 'autoconf',
   'libxslt1-dev', 'libc6-dev', 'libncurses5-dev', 'automake', 'ruby1.9.1-dev', 'libtool']:
    ensure => installed
  }

  # ExecJS runtime. The old Node.js will suffice.
  package { 'nodejs':
    ensure => latest
  }

  # Redis
  package { 'redis-server':
    ensure => installed
  }

  # Install zsh
  package { 'zsh':
    ensure => installed
  }

  # Install byobu
  package { 'byobu':
    ensure => installed
  }

  # Install vim
  package { 'vim':
    ensure => installed
  }

  # Install tar
  package { 'tar':
    ensure => installed
  }

  # Install wget
  package { 'wget':
    ensure => installed
  }

  package { "ruby":
    ensure => latest
  }

  package { "ruby1.9.3":
    ensure => latest
  }

  package { "ruby-switch":
    ensure => latest
  }

  package { "rubygems":
    ensure => latest
  }

  package { "rake":
    ensure => latest
  }

  exec {"switch_rubies":
    command => 'ruby-switch --set ruby1.9.1',
    require => [ Package["ruby-switch"], Package["ruby1.9.3"] ],
  }
}
class { 'install_packages': }

vcsrepo { "/home/vagrant/.rbenv":
  ensure   => latest,
  owner    => vagrant,
  group    => vagrant,
  provider => git,
  require => [Package['git'], Package['zsh']],
  source   => "https://github.com/sstephenson/rbenv.git",
  revision => 'master',
}->
vcsrepo { "/home/vagrant/.rbenv/plugins/ruby-build":
  ensure   => latest,
  owner    => vagrant,
  group    => vagrant,
  provider => git,
  require => [Package['git'], Package['zsh']],
  source   => "https://github.com/sstephenson/ruby-build.git",
  revision => 'master',
}->
vcsrepo { "/home/vagrant/.rbenv/plugins/rbenv-update":
  ensure   => latest,
  owner    => vagrant,
  group    => vagrant,
  provider => git,
  require => [Package['git'], Package['zsh']],
  source   => "https://github.com/rkh/rbenv-update.git",
  revision => 'master',
}->
rbenv::install { "vagrant":
  group => 'vagrant',
  home  => '/home/vagrant'
}->
rbenv::compile { "2.1.0":
  user => "vagrant",
  home => "/home/vagrant",
}->
rbenv::gem { 'pry':
  user => "vagrant",
  ruby => "2.1.0",
}->
rbenv::gem { 'awesome_print':
  user => "vagrant",
  ruby => "2.1.0",
}->
rbenv::gem { 'hirb':
  user => "vagrant",
  ruby => "2.1.0",
}->
rbenv::gem { 'rails':
  user => "vagrant",
  ruby => "2.1.0",
}->
rbenv::gem { 'pg':
  user => "vagrant",
  ruby => "2.1.0",
}

class install_phantom{

  # PhantomJS Dependency
  package { 'fontconfig':
    ensure => installed
  }

  exec {"phantom_wget":
    command => "wget http://phantomjs.googlecode.com/files/phantomjs-1.9.1-linux-x86_64.tar.bz2 -O /tmp/phantomjs-1.9.1-linux-x86_64.tar.bz2",
    unless  => "test -f /tmp/phantomjs-1.9.1-linux-x86_64.tar.bz2",
    require => [ Package["wget"] ],
  }

  # sudo tar xjf phantomjs-1.9.1-linux-x86_64.tar.bz2
  exec {"phantom_untar":
    cwd     => "/tmp/",
    command => "tar -xf /tmp/phantomjs-1.9.1-linux-x86_64.tar.bz2 phantomjs-1.9.1-linux-x86_64",
    unless  => "test -d /tmp/phantomjs-1.9.1-linux-x86_64",
    require => [ Package["tar"], Exec["phantom_wget"] ],
  }

  file { 'symlink_phantom':
    target => '/tmp/phantomjs-1.9.1-linux-x86_64/bin/phantomjs',
    ensure => 'link',
    path => '/usr/local/bin/phantomjs',
    require => Exec['phantom_untar'],
  }

}
class {'install_phantom':}

####### Configure Server Stuff #########

file { "/etc/motd":
    mode    => 600,
    owner   => "root",
    group   => "root",
    content => template("motd"),
}

# --- Manage the vagrant user --------------------------------------------------
user { 'vagrant':
  ensure     => "present",
  home    => '/home/vagrant',
  managehome => true,
  shell => "/bin/zsh"
}
file { '/home/vagrant':
    ensure  => directory,
    group   => vagrant,
    owner   => vagrant,
    mode    => 0700,
}

# Clone oh-my-zsh
vcsrepo { "/home/vagrant/.oh-my-zsh":
  ensure   => latest,
  owner    => vagrant,
  group    => vagrant,
  provider => git,
  require => [Package['git'], Package['zsh'], Package['curl']],
  source   => "http://github.com/robbyrussell/oh-my-zsh.git",
  revision => 'master',
}

file { '/home/vagrant/.zshrc':
  owner    => vagrant,
  group    => vagrant,
  content => template("dotfiles/zshrc"),
}
file { '/home/vagrant/.bashrc':
  owner    => vagrant,
  group    => vagrant,
  content => template("dotfiles/bashrc"),
}
file { '/home/vagrant/.aliases':
  owner    => vagrant,
  group    => vagrant,
  content => template("dotfiles/aliases"),
}
file { '/home/vagrant/.irbrc':
  owner    => vagrant,
  group    => vagrant,
  content => template("dotfiles/irbrc"),
}
file { '/home/vagrant/.gemrc':
  owner    => vagrant,
  group    => vagrant,
  content => template("dotfiles/gemrc"),
}
file { '/home/vagrant/.tmux.conf':
  owner    => vagrant,
  group    => vagrant,
  content => template("dotfiles/tmux.conf"),
}
file { '/home/vagrant/.gemrc':
  owner    => vagrant,
  group    => vagrant,
  content => template("dotfiles/gemrc"),
}
file { '/home/vagrant/bundle/config':
  owner    => vagrant,
  group    => vagrant,
  content => template("dotfiles/bundle/config"),
}


file { '/home/vagrant/.ssh/':
    ensure  => directory,
    group   => vagrant,
    owner   => vagrant,
    mode    => 0600,
} ->
exec{ 'add_bitbucket_to_known':
  command => "ssh-keyscan -t rsa bitbucket.org >> /home/vagrant/.ssh/known_hosts"
} ->
exec{ 'add_github_to_known':
  command => "ssh-keyscan -t rsa github.com >> /home/vagrant/.ssh/known_hosts"
}

service { "redis-server":
  enable => true,
  ensure => running,
  #hasrestart => true,
  #hasstatus => true,
  #require => Class["config"],
}
