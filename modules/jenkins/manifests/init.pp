class jenkins { 

  yumrepo { jenkins: 
    baseurl => "http://pkg.jenkins-ci.org/redhat",
    enabled => 1,
    name => jenkins,
    gpgcheck => 0,
  }

  package { jenkins: ensure => present }
  package { 'java-1.7.0-openjdk': ensure => present}
  package { 'java-1.7.0-openjdk-devel': ensure => present}
  #package { dejavu-lgc-sans-fonts: ensure => present}
  #package { dejavu-lgc-sans-mono-fonts: ensure => present}
  package { tomcat6: ensure => present}
  package { git: ensure => latest}
  #package { publican: ensure => latest}
  package { mysql-connector-java: ensure => present}
  package { maven: ensure => present} 
  package { wget: ensure => present} 
  service { jenkins: 
    require => Package[jenkins],
    enable => true,
    hasstatus => true,
    ensure => true,
  }

  iptables { 'http80':
    proto => 'tcp',
    dport => '80',
    jump  => 'ACCEPT',
  }

  firewall { 'http8080':
    ensure => absent,
    proto  => 'tcp',
    dport  => '8080',
    action => 'ACCEPT',
  }

  users::priv_user { 'edison': }
  users::priv_user { 'prasanna': }
}
