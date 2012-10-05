class nfsclient { 
	case $operatingsystem  {
	  redhat,centos: { 
      $nfspacks = [ "nfs-utils", "nfs-utils-lib", "rpcbind" ]
      package { $nfspacks:
        ensure => installed,
      }
	    service { "rpcbind" :
	     ensure  => running,
       require => Package[$nfspacks],
      }
      service { "nfslock" :
        ensure => running,
        require => Package[$nfspacks],
      }
    }
	  ubuntu: {
      $nfspacks = [ "nfs-common", "rpcbind" ]
      package { $nfspacks:
        ensure => installed,
        require => Package[$nfspacks],
      }
	    service { "portmap" :
	      ensure => running,
        require => Package[$nfspacks],
	    }
	  }
	}
}
