class jenkins { 

  yumrepo { jenkins: 
    baseurl  => "http://pkg.jenkins-ci.org/redhat",
    enabled  => 1,
    name     => jenkins,
    gpgcheck => 0,
  }

  package { jenkins: ensure                    => present }
  package { 'java-1.7.0-openjdk': ensure       => present}
  package { 'java-1.7.0-openjdk-devel': ensure => present}
  package { 'createrepo' : ensure              => present}
  package { tomcat6: ensure                    => present}
  package { git: ensure                        => latest}
  package { mysql-connector-java: ensure       => present}
  package { maven: ensure                      => present}
  package { wget: ensure                       => present}

  service { jenkins: 
    require   => Package[jenkins],
    enable    => true,
    hasstatus => true,
    ensure    => true,
  }

  firewall { '112 http80':
    proto  => 'tcp',
    dport  => '80',
    action => accept,
  }

  firewall { '113 http8080':
    proto  => 'tcp',
    dport  => '8080',
    action => accept,
  }

  users::priv_user { 'edison': }
  users::priv_user { 'prasanna': }
}
