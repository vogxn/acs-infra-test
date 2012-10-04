class nfsclient { 
	case $operatingsystem  {
	  redhat,centos: { 
      $nfspacks = [ "nfs-utils", "nfs-utils-lib", "rpcbind" ]
      package { $nfspacks:
        ensure => installed,
      }
	    service { "rpcbind" :
	     ensure => running,
      }
      service { "nfslock" :
        ensure => running,
      }
    }
	  ubuntu: {
      $nfspacks = [ "nfs-common", "rpcbind" ]
      package { $nfspacks:
        ensure => installed,
      }
	    service { "portmap" :
	      ensure => running,
	    }
	  }
	}
}
