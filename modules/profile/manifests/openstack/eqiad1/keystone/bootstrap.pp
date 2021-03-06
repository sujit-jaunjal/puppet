class profile::openstack::eqiad1::keystone::bootstrap(
    $region = lookup('profile::openstack::eqiad1::region'),
    $db_pass = lookup('profile::openstack::eqiad1::keystone::db_pass'),
    $admin_token = lookup('profile::openstack::eqiad1::keystone::admin_token'),
    ) {

    require ::profile::openstack::eqiad1::keystone::service
    class {'::profile::openstack::base::keystone::bootstrap':
        admin_token => $admin_token,
        db_pass     => $db_pass,
        region      => $region
    }
    contain '::profile::openstack::base::keystone::bootstrap'
}
