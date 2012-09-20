class mysql {
  package { "mysql-server":
    name     => $operatingsystem? {
      centos => ["mysql-server", "mysql-connector-java", "mysql"],
      redhat => ["mysql-server", "mysql-connector-java", "mysql"],
      debian => ["mysql-server", "mysql-client"],
      ubuntu => ["mysql-server", "mysql-client"],
    },
    ensure   => installed,
  }

  service { "mysqld":
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package[ "mysql-server" ],
  }
}
