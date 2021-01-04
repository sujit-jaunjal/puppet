class openstack::nova::api::service::rocky(
    Stdlib::Port $api_bind_port,
    Stdlib::Port $metadata_bind_port,
) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::rocky::${::lsbdistcodename}"

    package { 'nova-api':
        ensure => 'present',
    }

    # firstboot/user_data things:
    file { '/usr/lib/python3/dist-packages/wmfnovamiddleware':
        ensure  => 'absent',
        recurse => true,
    }
    file { '/etc/nova/userdata.txt':
        ensure  => 'absent',
    }

    # Hack in regex validation for instance names.
    #  Context can be found in T207538
    file { '/usr/lib/python3/dist-packages/nova/api/openstack/compute/servers.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/openstack/rocky/nova/hacks/servers.py',
        require => Package['nova-api'];
    }
}
