class fw_base::pre {
  Firewall {
    require => undef,
  }

  firewall { '000 allow packets with valid state':
    state  => ['RELATED', 'ESTABLISHED'],
    action => accept,
  }->
  firewall { '001 allow icmp':
    proto  => 'icmp',
    action => accept,
  }->
  firewall { '002 allow all to lo interface':
    iniface => 'lo',
    action  => accept,
  }->
  firewall { '100 allow ssh':
    proto  => 'tcp',
    dport  => '22',
    action => accept,
  }

  resources { 'firewall':
    purge => false,
  }
}

class fw_base::post {
  firewall { '999 drop everything else':
    proto  => all,
    action => reject,
    before => undef,
  }
}

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

}
