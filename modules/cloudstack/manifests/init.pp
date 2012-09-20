#Apache Cloudstack - Module for the Management Server

class cloudstack::no_selinux {
  file { "/etc/selinux/config":
    source => "puppet://puppet/cloudstack/config",
  }
  exec { "/usr/sbin/setenforce 0":
    onlyif => "/usr/sbin/getenforce | grep Enforcing",
  }
}

class cloudstack {
  include cloudstack::no_selinux

  #TODO: Repo replace from nodes.pp
  $repo = "http://10.223.75.10/repo/rpm/master/"
  #TODO: Should this be fixed?
  $cs_mgmt_server = "10.223.75.111"
  $sysvm_url_kvm = "http://download.cloud.com/releases/2.2.0/systemvm.qcow2.bz2"
  $sysvm_url_xen = "http://download.cloud.com/releases/2.2.0/systemvm.vhd.bz2"

  $packages = ["wget", "mysql-server"] 
  package { $packages: 
      ensure => installed,
  }
  
  #For mounting the secondary and ISO 
  package { "nfs-utils":
    name     => $operatingsystem ? {
      centos => "nfs-utils",
      redhat => "nfs-utils",
      debian => ["nfs-common", "nfs-kernel-server"]
      ubuntu => ["nfs-common", "nfs-kernel-server"]
    }
    ensure => installed,
  }

  #Needed for systemvm.iso
  package { "mkisofs":
    name => $operatingsystem ? {
      centos => "cdw",
      redhat => "cdw",
      debian => "genisoimage",
      ubuntu => "genisoimage",
    }
    ensure => installed,
  }

  service { "mysqld":
    ensure  => running,
    require => Package["mysql-server"],
  }

  service { "nfs":
    ensure => running,
    require => Package["nfs-utils"],
  }

  #Fetch latest from repo
  exec { "/usr/bin/wget -m $repo -nH --cut-dirs=2 -np -L -P cloudstack --reject=index.html*":
    cwd => "/tmp",
    creates => "/tmp/cloudstack",
  }

  file { "/tmp/cloudstack":
    ensure => directory,
  }

  exec { "/bin/mv master/build* master/build":
    cwd     => "/tmp/cloudstack/",
    creates => "/tmp/cloudstack/master/build",
  }

  case $operatingsystem {
    centos,redhat : {
      yumrepo { "cstemp":
        baseurl  => "file:///tmp/cloudstack/master/build",
        enabled  => 1,
        gpgcheck => 0,
        name     => "cstemp"
      }
      $packagelist =  [ "cloud-server", "cloud-client", "cloud-usage"]
      package { $packagelist:
         ensure  => installed,
         require => Yumrepo["cstemp"],
      }
    }
    ubuntu, debian: {
    }
    fedora : {
    }
  }

  file { "/etc/sudoers":
    source => "puppet://puppet/cloudstack/sudoers",
    mode   => 440,
    owner  => root,
    group  => root,
  }

  file { "/etc/hosts":
    content => template("cloudstack/hosts"),
  }

  iptables { "apiport":
    proto => "tcp",
    dport => [8096, 8080],
    jump  => "ACCEPT",
  }

  iptables { "nfsudp":
    proto => "udp",
    dport => 2049,
    jump  => "ACCEPT",
  }

  iptables { "nfstcp":
    proto => "tcp",
    dport => 2049,
    jump  => "ACCEPT",
  }
}
