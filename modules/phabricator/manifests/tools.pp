# == Class: phabricator::tools
#
# Tools and such needed to migrate 3rd party content
# and perform administrative tasks.
#
class phabricator::tools (
    Stdlib::Fqdn $dbmaster_host       = 'localhost',
    Integer $dbmaster_port      = 3306,
    Stdlib::Fqdn $dbslave_host        = 'localhost',
    Integer $dbslave_port       = 3323,
    Stdlib::Unixpath $directory = '/srv/phab/tools',
    String $deploy_target       = 'phabricator/deployment',
    String $manifest_user       = '',
    String $manifest_pass       = '',
    String $app_user            = '',
    String $app_pass            = '',
    String $bz_user             = '',
    String $bz_pass             = '',
    String $rt_user             = '',
    String $rt_pass             = '',
    String $phabtools_cert      = '',
    String $phabtools_user      = '',
    String $gerritbot_token     = '',
    Boolean $dump               = false,
) {

    package { 'python-mysqldb': ensure => present }

    file { '/etc/phabtools.conf':
        content => template('phabricator/phabtools.conf.erb'),
        require => Package[$deploy_target],
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
    }

    file { '/srv/dumps':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/srv/dumps/WARNING_NEVER_PUT_PRIVATE_DATA_HERE_THIS_IS_SYNCED_TO_PUBLIC':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    $dump_script = "${directory}/public_task_dump.py 1>/dev/null"

    file { $dump_script:
        mode    => '0555',
        require => Package[$deploy_target],
    }

    $dump_cron_ensure = $dump ? {
        true    => present,
        default => absent,
    }
    cron { $dump_script:
        ensure  => $dump_cron_ensure,
        command => $dump_script,
        user    => root,
        hour    => '2',
        minute  => '0',
        require => Package[$deploy_target],
    }

    # clean up old tmp files (T150396)
    cron { 'phab_clean_tmp':
        ensure  => present,
        command => '/usr/bin/find /tmp -user www-data -mtime +14 | xargs rm -rf',
        user    => 'www-data',
        hour    => '7',
    }
}
