# /etc/puppet/manifests/site.pp
#
import "modules"
import "nodes"
import "infrastructure"
filebucket { main: server => puppet }

# global defaults
File { backup => main }
Exec { path => "/usr/bin:/usr/sbin/:/bin:/sbin" }

Package {
        provider => $operatingsystem ? {
                debian => aptitude,
                ubuntu => aptitude,
                redhat => yum,
                fedora => yum,
                centos => yum,
        }
}


# Always persist firewall rules
exec { 'persist-firewall':
  command     => $operatingsystem ? {
    'debian'          => '/sbin/iptables-save > /etc/iptables/rules.v4',
    /(RedHat|CentOS)/ => '/sbin/iptables-save > /etc/sysconfig/iptables',
  },
  refreshonly => true,
}

# These defaults ensure that the persistence command is executed after 
# every change to the firewall, and that pre & post classes are run in the
# right order to avoid potentially locking you out of your box during the
# first puppet run.
Firewall {
  notify  => Exec['persist-firewall'],
  require => Class['base::pre'],
  before  => Class['base::post'],
}
Firewallchain {
  notify  => Exec['persist-firewall'],
}

# Purge unmanaged firewall resources
#
# This will clear any existing rules, and make sure that only rules
# defined in puppet exist on the machine
#resources { "firewall":
#  purge => true
#}
