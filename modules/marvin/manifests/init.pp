#Apache Cloudstakc - Marvin agent

class marvin  {
  $packages = ["nc", "gcc", "make", "bzip2", "bzip2-devel", "readline", "readline-devel", "sqlite3", "sqlite3-devel"]
  package { $packages:
    ensure => installed,
  }
}
