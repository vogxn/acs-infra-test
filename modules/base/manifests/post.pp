class base::post {
  #  firewall { '999 drop everything else':
  #  proto  => all,
  #  action => reject,
  #  before => undef,
  #}
}
