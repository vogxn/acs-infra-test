#Apache CloudStack - infrastructure and nodes

node acs-qa-h20 inherits basenode {
  include ssh
  include cloudstack::agent
}

node acs-qa-h11 inherits basenode {
  include ssh
  include cloudstack::agent
}

node acs-qa-h23 inherits basenode {
  include ssh
  include cloudstack::agent
}

node acs-qa-h21 inherits basenode {
  include ssh
  include cloudstack::agent
}


node cloudstack-rhel inherits basenode {
  include mysql
  include nfsclient
  include cloudstack
  include ntp
}

node cloudstack-ubuntu inherits basenode {
  include mysql
  include nfsclient
  include cloudstack
  include ntp
}

node jenkins-internal inherits basenode {
  include mysql
  include jenkins
}

node marvin inherits basenode {
  include mysql
  include ssh
  include marvin
}
