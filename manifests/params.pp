class zk_puppet::params {
  case $::operatingsystem {
    "Debian", "Ubuntu": {
      $rubydevel_package = "ruby-dev"
      $patch_package = "patch"
      $gcc_package = "gcc"
    }
    default:  {
      $rubydevel_package = "ruby-devel"
      $patch_package = "patch"
      $gcc_package = "gcc"
    }
  }
}