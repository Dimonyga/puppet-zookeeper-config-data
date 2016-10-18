#
# puppet-zookeeper module, for managing configuration data via puppet (storing
# in zookeeper)
#
# This class installs the pre-requisites.
# See the lib/ directory for the goodies, and README.md for usage.
#
class zk_puppet inherits zk_puppet::params {

    # gems these parser functions require:
    package { ['zk',]:
      ensure   => installed,
      provider => $puppetgem,
      require => [
        Package[$rubydevel_package],
        Package[$patch_package],
        Package[$gcc_package],
        Package[$make_package],
      ]
    }

  if ! defined (Package[$rubydevel_package]) {
    package { $rubydevel_package:
        ensure => present,
    }
  }
  if ! defined (Package[$patch_package]) {
    package { $patch_package:
      ensure => present,
    }
  }
  if ! defined (Package[$gcc_package]) {
    package { $gcc_package:
      ensure => present,
    }
  }
  if ! defined (Package[$make_package]) {
    package { $make_package:
      ensure => present,
    }
  }
}
