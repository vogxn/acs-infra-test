#Apache Cloudstack - Module for the Management Server and Agent
#

class common::data {
  $nameservers = ['10.223.75.10', '10.223.110.254', '8.8.8.8']
  $puppetmaster = '10.223.75.10'
}

class cloudstack {
  case $operatingsystem  {
    centos: { include cloudstack::no_selinux }
    redhat: { include cloudstack::no_selinux }
  }
  include cloudstack::repo
  include cloudstack::ports
  include cloudstack::files
  include common::data
  include mysql

  #TODO: Update to latest systemvm urls
  $sysvm_url_kvm = 'http://download.cloud.com/releases/2.2.0/systemvm.qcow2.bz2'
  $sysvm_url_xen = 'http://download.cloud.com/releases/2.2.0/systemvm.vhd.bz2'

  $packages = ['wget'] 
  package { $packages: 
      ensure => installed,
  }
  
  #Needed for systemvm.iso
  package { 'genisoimage':
    ensure => installed,
  }

  exec {'/bin/bash /root/secseeder.sh':
    require => Class[cloudstack::files],
    timeout => 0,
  }
  
  file { '/usr/share/cloud/setup/templates.sql':
    source  => 'puppet:///cloudstack/templates.sql',
    mode    => 644,
    owner   => root,
    group   => root,
    before  => Exec['cloud-setup-databases cloud:cloud@localhost --deploy-as=root'],
    require => [Package['cloud-client'], Package['cloud-server']],
  }

  exec {'cloud-setup-databases cloud:cloud@localhost --deploy-as=root':
    creates  => '/var/lib/mysql/cloud',
    require => [Package['cloud-client'], Package['cloud-server']],
    before   => Exec['cloud-setup-management'],
  }
  exec {'cloud-setup-management':
    creates => '/var/run/cloud-management.pid',
    before  => Service['cloud-management'],
  }

  case $operatingsystem {
    centos,redhat : {
      $packagelist =  [ 'cloud-server', 'cloud-client']
      package { $packagelist:
         ensure  => installed,
         require => Yumrepo['cstemp'],
      }
      file { '/etc/yum.repos.d/cstemp.repo':
        ensure => absent,
      }
    }
    ubuntu, debian: {
      $packagelist =  [ 'cloud-server', 'cloud-client']
      package { $packagelist:
         ensure  => latest,
         require => File['/etc/apt/sources.list.d/cloudstack.list'],
      }
    }
    fedora : {
    }
  }

  service { 'cloud-management':
    ensure => running,
  }

  file { '/root/mslog':
    ensure  => link,
    target  => '/var/log/cloud/management/management-server.log',
    owner   => 'root',
    mode    => 644,
    require => Service['cloud-management'],
  }

  file { '/var/log/cloud/management/management-server.log':
    ensure  => present,
    owner   => 'cloud',
    group   => 'cloud',
    mode    => 644,
    require => Service['cloud-management']
  }
  file { '/var/log/cloud/management/api-server.log':
    ensure  => present,
    owner   => 'cloud',
    group   => 'cloud',
    mode    => 644,
    require => Service['cloud-management']
  }
}

class cloudstack::agent {
  case $operatingsystem  {
    centos: { include cloudstack::no_selinux }
    redhat: { include cloudstack::no_selinux }
  }
  include cloudstack::repo
  include cloudstack::files
  include common::data

  case $operatingsystem {
    centos,redhat : {
      $packagelist =  [ 'cloud-agent' ]
      package { $packagelist:
         ensure  => installed,
         require => Yumrepo['cstemp'],
      }
    }
    ubuntu, debian: {
      $packagelist =  [ 'cloud-agent' ]
      package { $packagelist:
         ensure  => latest,
         require => [File['/etc/apt/sources.list.d/cloudstack.list'], Exec['apt-get update']],
      }
    }
    fedora : {
    }
  }

  package { NetworkManager:
    ensure => absent,
  }

  #exec {"sed -i 's/IPADDR=@ipaddress_em1/IPADDR=@ipaddress_em1/g' /etc/sysconfig/network-scripts/ifcfg-em1":
  #}

  #  exec {"sed -i 's/\"dhcp\"/\"static\"/g' /etc/sysconfig/network-scripts/ifcfg-em*":
  #}

  exec {"sed -i '/NM_CONTROLLED=/d' /etc/sysconfig/network-scripts/ifcfg-*":
    notify => Notify['networkmanager'],
  }

  notify { 'networkmanager':
    message => 'NM_Controlled set to off'
  }
}

class cloudstack::no_selinux {
  file { '/etc/selinux/config':
    source => 'puppet:///cloudstack/config',
  }
  exec { '/usr/sbin/setenforce 0':
    onlyif => '/usr/sbin/getenforce | grep Enforcing',
  }
}

class cloudstack::repo {
  #TODO: Repo replace from nodes.pp
  $yumrepo = 'puppet:///cloudstack/yumrepo'
  #Wido D. Hollander's repo
  $aptrepo = 'http://cloudstack.apt-get.eu/ubuntu'
  $aptkey = 'http://cloudstack.apt-get.eu/release.asc'

  case $operatingsystem {
    centos,redhat : {
      file { '/tmp/cloudstack' :
        source  => 'puppet:///cloudstack/yumrepo',
        recurse => true,
        owner   => 'root',
        mode    => 0644,
        group   => 'root',
        ensure  => directory,
        path    => '/tmp/cloudstack',
      }
      yumrepo { 'cstemp':
        baseurl  => 'file:///tmp/cloudstack',
        enabled  => 1,
        gpgcheck => 0,
        name     => 'cstemp',
      	require => File['/tmp/cloudstack'],
      }
    }
    ubuntu, debian: {
      file { '/etc/apt/sources.list.d/cloudstack.list':
        ensure  => present,
        content => 'deb ${aptrepo} ${lsbdistcodename} 4.0',
      }
      exec { 'wget -O - ${aptkey} | apt-key add -': 
        path => ['/usr/bin', '/bin'],
      }
      exec { 'apt-get update':
        path => ['/usr/bin', '/bin'],
      }
    }
    fedora : {
    }
  }
}

class cloudstack::ports {
  firewall { '010 integrationport':
    proto     => 'tcp',
    dport     => 8096,
    action    => accept,
  }
  firewall { '011 apiport':
    proto     => 'tcp',
    dport     => 8080,
    action    => accept,
  }
  firewall { '012 clusterport':
    proto     => 'tcp',
    dport     => 9090,
    action    => accept,
  }
  firewall { '013 agentport':
    proto     => 'tcp',
    dport     => 8250,
    action    => accept,
  }

  firewall { '014 mysqlport':
    proto  => 'tcp',
    dport  => 3306,
    action => accept,
  }

  firewall { '015 nfsudp':
    proto  => 'udp',
    dport  => 2049,
    action => accept,
  }

  firewall { '016 nfstcp':
    proto  => 'tcp',
    dport  => 2049,
    action => accept,
  }
}

class cloudstack::files {
  include common::data
  $nameservers = $common::data::nameservers
  file { '/etc/sudoers':
    source => 'puppet:///cloudstack/sudoers',
    mode   => 440,
    owner  => root,
    group  => root,
  }

  file { '/etc/hosts':
    content => template('cloudstack/hosts'),
  }

  file { '/etc/resolv.conf':
    content => template('cloudstack/resolv.conf'),
  }

  file { '/root/redeploy.sh':
    source  => 'puppet:///cloudstack/redeploy.sh',
    mode    => 744,
  }

  file { '/root/secseeder.sh':
    source  => 'puppet:///cloudstack/secseeder.sh',
    mode    => 744,
  }

  case $operatingsystem {
    redhat,centos: { 
    file { '/etc/sysconfig/network':
      content => template('cloudstack/network'),
    }
    }
    default: {}
  }
}
