class dnsmasq {

  $dnspacks = ["dnsmasq", "dnsmasq-base", "dnsmasq-utils"]
  package { $dnspacks:
    ensure => installed,
  }

  service { "dnsmasq":
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package[$dnspacks],
  }

  file { "dnsmasq.d"
      mode      => 600,
      owner     => root,
      group     => root,
      ensure    => directory,
      path      => $operatingsystem? {
        default => "/etc/dnsmasq.d",
        notify  => Service["dnsmasq"],
      },
      source  => "puppet:///dnsmasq/dnsmasq.d",
      recurse => true,
  }

  file { "dnsmasq.conf"
      mode      => 400,
      owner     => root,
      group     => root,
      ensure    => present,
      path      => $operatingsystem? {
        default => "/etc/dnsmasq.conf",
        notify  => Service["dnsmasq"],
      },
      source => "puppet:///dnsmasq/dnsmasq.conf",
  }
}
