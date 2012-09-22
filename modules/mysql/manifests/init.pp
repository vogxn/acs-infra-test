class mysql {
  package { "mysql-server":
    name     => $operatingsystem? {
      centos => ["mysql-server", "mysql"],
      redhat => ["mysql-server", "mysql"],
      debian => ["mysql-server", "mysql-client"],
      ubuntu => ["mysql-server", "mysql-client"],
    },
    ensure   => installed,
  }

  service { "mysqld":
    name            => $operatingsystem? {
      centos,redhat => "mysqld",
      ubuntu,debian => "mysql",
      default       => "mysqld",
    }
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package[ "mysql-server" ],
  }
}
