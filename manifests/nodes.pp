#Apache CloudStack - infrastructure and nodes

node 'puppet' {
	include puppet::master
  include ntp
        
}

node 'marvin' inherits basenode {
    include marvin
}

node 'cs-mgmt' inherits basenode {
  include cloudstack
  include mysql
  include nfs
}

node 'jenkins' inherits basenode {
  include jenkins
}
