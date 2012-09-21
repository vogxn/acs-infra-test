#Apache CloudStack - infrastructure and nodes

node 'learn' {
  #  include cloudstack
  include mysql
  include ntp
  include ssh
  include dhcpd
  include puppet
}

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
