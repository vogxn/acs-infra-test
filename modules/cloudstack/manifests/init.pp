#Apache Cloudstack - Module for the Management Server and Agent
#

class cloudstack {
  case $operatingsystem  {
    centos: { include cloudstack::no_selinux }
    redhat: { include cloudstack::no_selinux }
  }
  include cloudstack::repo
  include cloudstack::ports
  include cloudstack::files
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
    require => [Class[cloudstack::files], Exec['cloudstack-setup-management']],
    timeout => 0,
    logoutput => true,
  }
  
  file { '/usr/share/cloudstack-management/setup/templates.sql':
    source  => 'puppet:///cloudstack/templates.sql',
    mode    => 644,
    owner   => root,
    group   => root,
    before  => Exec['cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root'],
    require => [Package['cloudstack-common'], Package['cloudstack-management']],
  }

  exec {'cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root':
    creates  => '/var/lib/mysql/cloud',
    require => [Package['cloudstack-common'], Package['cloudstack-management']],
    before   => Exec['cloudstack-setup-management'],
  }
  exec {'cloudstack-setup-management':
    creates => '/var/run/cloudstack-management.pid',
    before  => Service['cloudstack-management'],
  }

  case $operatingsystem {
    centos,redhat : {
      $packagelist =  [ 'cloudstack-management', 'cloudstack-common']
      package { $packagelist:
         ensure  => installed,
         require => Yumrepo['cstemp'],
      }
      file { '/etc/yum.repos.d/cstemp.repo':
        ensure => absent,
      }
    }
    ubuntu, debian: {
      $packagelist =  [ 'cloudstack-management', 'cloudstack-common']
      package { $packagelist:
         ensure  => latest,
         require => File['/etc/apt/sources.list.d/cloudstack.list'],
      }
    }
    fedora : {
    }
  }

  service { 'cloudstack-management':
    ensure => running,
  }
  
  #Seed the syslog enabled log4j
  file {'/etc/cloudstack/management/log4j-cloud.xml':
        source => 'puppet:///cloudstack/log4j-management.xml',
        mode   => 744,
        require => Service['cloudstack-management'], 
  }
  file { '/root/mslog':
    ensure  => link,
    target  => '/var/log/cloudstack/management/management-server.log',
    owner   => 'root',
    mode    => 644,
    require => Service['cloudstack-management'],
  }
  file { '/usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/vhd-util':
    source => 'puppet:///cloudstack/vhd-util',
    ensure => present,
    owner => 'root',
    mode => 755,
    require => Service['cloudstack-management'],
  }
  file { '/var/log/cloudstack/management/management-server.log':
    ensure  => present,
    owner   => 'cloud',
    group   => 'cloud',
    mode    => 644,
    require => Service['cloudstack-management']
  }
  file { '/var/log/cloudstack/management/apilog.log':
    ensure  => present,
    owner   => 'cloud',
    group   => 'cloud',
    mode    => 644,
    require => Service['cloudstack-management']
  }
}

class cloudstack::agent {
  $netmask='255.255.255.192'

  case $operatingsystem  {
    centos: { include cloudstack::no_selinux }
    redhat: { include cloudstack::no_selinux }
  }
  include cloudstack::repo
  include cloudstack::files

  case $operatingsystem {
    centos,redhat : {
      $packagelist =  [ 'cloudstack-agent', 'qemu-kvm', 'expect' ]
      package { $packagelist:
         ensure  => installed,
         require => Yumrepo['cstemp'],
      }
      service { 'libvirtd':
        ensure => running,
        require => Package['qemu-kvm'],
      }
    }
    ubuntu, debian: {
      $packagelist =  [ 'cloudstack-agent', 'qemu-kvm' ]
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

  case $operatingsystem {
    centos, redhat : {
      exec {"/bin/echo 'IPADDR=$ipaddress_em1' >> /etc/sysconfig/network-scripts/ifcfg-em1":
        path   => "/etc/sysconfig/network-scripts/",
        onlyif => '/bin/grep -vq IPADDR /etc/sysconfig/network-scripts/ifcfg-em1'
      }

      exec {"/bin/echo 'NETMASK=$netmask' >> /etc/sysconfig/network-scripts/ifcfg-em1":
        path => "/etc/sysconfig/network-scripts/",
        onlyif => '/bin/grep -vq NETMASK /etc/sysconfig/network-scripts/ifcfg-em1'
      }

      exec {"/bin/sed -i 's/\"dhcp\"/\"static\"/g' /etc/sysconfig/network-scripts/ifcfg-em*":
      }

      exec {"/bin/sed -i '/NM_CONTROLLED=/d' /etc/sysconfig/network-scripts/ifcfg-*":
        notify => Notify['networkmanager'],
      }

      notify { 'networkmanager':
        message => 'NM_Controlled set to off'
      }

      file {'/etc/sysconfig/network-scripts/ifcfg-eth0':
        ensure => absent,
      }

      file { '/etc/cloudstack/agent/agent.properties':
        source  => 'puppet:///cloudstack/agent.properties',
        mode    => 744,
        require => Package['cloudstack-agent'],
      }

      file {'/etc/cloudstack/agent/log4j-cloud.xml':
        source => 'puppet:///cloudstack/log4j-agent.xml',
        mode   => 744,
        require => File['/etc/cloudstack/agent/agent.properties'],
      }
    }
    ubuntu, debian: {
      #Still to figure out ubuntu idiosyncracies
      }
  }
}

class cloudstack::no_selinux {
  file { '/etc/selinux/config':
    source => 'puppet:///cloudstack/config',
  }
  exec { '/usr/sbin/setenforce 0':
    onlyif => '/usr/sbin/getenforce | /bin/grep Enforcing',
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
  file { '/etc/sudoers':
    source => 'puppet:///cloudstack/sudoers',
    mode   => 440,
    owner  => root,
    group  => root,
  }

  file { '/etc/hosts':
    content => template('cloudstack/hosts'),
  }

  #  file { '/etc/resolv.conf':
  #  content => template('cloudstack/resolv.conf'),
  #}

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
