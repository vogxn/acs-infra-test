#Apache CloudStack - infrastructure and nodes


node cloudstack-rhel inherits basenode {
  include mysql
  include cloudstack
  include ntp
}

node cloudstack-ubuntu inherits basenode {
  include mysql
  include cloudstack
  include ntp
}

node jenkins inherits basenode {
  include mysql
  include jenkins
}

node marvin inherits basenode {
  include mysql
  include ssh
  include marvin
}


