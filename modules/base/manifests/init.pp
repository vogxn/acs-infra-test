class base {
  package { screen:
    ensure => latest 
  }
  package { vim-enhanced:
    ensure => latest,
  }
  package { iptables:
    ensure => latest,
    notify => Service['iptables'],
  }

  service { 'iptables':
    ensure      => running,
    hasstatus   => true,
    hasrestart  => true,
  }
  include base::pre
  include base::post

}
