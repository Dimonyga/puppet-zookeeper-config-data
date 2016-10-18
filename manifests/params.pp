class zk_puppet::params {
  if $::puppetversion and versioncmp($::puppetversion, '4.0.0') >= 0 {
    $puppetgem = 'puppet_gem'
  } else {
    $puppetgem = 'gem'
  }
  case $::operatingsystem {
    "Debian", "Ubuntu": {
      $rubydevel_package = "ruby-dev"
      $patch_package = "patch"
      $gcc_package = "gcc"
      $make_package = "make"
    }
    default:  {
      $rubydevel_package = "ruby-devel"
      $patch_package = "patch"
      $gcc_package = "gcc"
      $make_package = "make"
    }
  }
}