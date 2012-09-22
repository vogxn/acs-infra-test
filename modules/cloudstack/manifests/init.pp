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
  $yumrepo = "puppet://puppet/cloudstack/yumrepo"
  #Wido D. Hollander's repo
  $aptrepo = "http://cloudstack.apt-get.eu/ubuntu"

  #TODO: Update to latest systemvm urls
  $sysvm_url_kvm = "http://download.cloud.com/releases/2.2.0/systemvm.qcow2.bz2"
  $sysvm_url_xen = "http://download.cloud.com/releases/2.2.0/systemvm.vhd.bz2"

  $packages = ["wget"] 
  package { $packages: 
      ensure => installed,
  }
  
  #For mounting the secondary and ISO 
  package { "nfs-utils":
    name     => $operatingsystem ? {
      centos => "nfs-utils",
      redhat => "nfs-utils",
      debian => ["nfs-common", "nfs-kernel-server"],
      ubuntu => ["nfs-common", "nfs-kernel-server"]
    },
    ensure => installed,
  }

  #Needed for systemvm.iso
  package { "genisoimage":
    ensure => installed,
  }

  service { "nfs":
    name      => $operatingsystem? {
      ubuntu  => "nfs-kernel-server",
      default => "nfs"
    },
    ensure  => running,
    require => Package["nfs-utils"],
  }

  #Fetch latest from repo
  #exec { "/usr/bin/wget -m $repo -nH --cut-dirs=2 -np -L -P cloudstack --reject=index.html*":
  #  cwd => "/tmp",
  #  creates => "/tmp/cloudstack",
  #}

  #exec { "/bin/mv master/build* master/build":
  #  cwd     => "/tmp/cloudstack/",
  #  creates => "/tmp/cloudstack/master/build",
  #}

  case $operatingsystem {
    centos,redhat : {
      #TODO: Latest cloudstack build copied to puppetmaster
      file { "/tmp/cloudstack" :
        source  => "puppet://puppet/cloudstack/yumrepo",
        recurse => true,
        owner   => "root",
        mode    => 0644,
        group   => "root",
        ensure  => directory,
        path    => "/tmp/cloudstack",
      }
      yumrepo { "cstemp":
        baseurl  => "file:///tmp/cloudstack",
        enabled  => 1,
        gpgcheck => 0,
        name     => "cstemp",
	require => File["/tmp/cloudstack"],
      }
      $packagelist =  [ "cloud-server", "cloud-client"]
      package { $packagelist:
         ensure  => installed,
         require => Yumrepo["cstemp"],
      }
      file { "/etc/yum.repos.d/cstemp.repo":
        ensure => absent,
      }
    }
    ubuntu, debian: {
      exec { "echo \"deb $aptrepo $(lsb_release -s -c) 4.0\" > /etc/apt/sources.list.d/cloudstack.list": 
        creates => "/etc/apt/sources.list.d/cloudstack.list",
      }
      exec { "wget -O - $aptrepo/release.asc | apt-key add -": 
      }
      $packagelist =  [ "cloud-server", "cloud-client"]
      package { $packagelist:
         ensure  => installed,
      }
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
