class builder {

  $antpacks = [ "ant", "ant-apache-log4j", "ant-contrib", "ant-nodeps", "ant-javadoc"]
  package { $antpacks :
    ensure => present,
  }

  $mavenpacks = ["maven", "maven-ant-helper"]
  package { $antpacks :
    ensure => present,
  }
}
