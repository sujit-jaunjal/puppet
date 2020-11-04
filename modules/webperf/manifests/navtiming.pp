# == Class: webperf::navtiming
#
# Captures NavigationTiming events from Kafka and send them to StatsD / Graphite.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# https://www.mediawiki.org/wiki/Extension:NavigationTiming
#
# === Parameters
#
# [*kafka_brokers*]
#   String of comma separated Kafka bootstrap brokers.
#
# [*statsd_host*]
#   Write stats to this StatsD instance. Default: '127.0.0.1'.
#
# [*statsd_port*]
#   Write stats to this StatsD instance. Default: 8125.
#
class webperf::navtiming(
    String $kafka_brokers,
    Stdlib::Host $statsd_host = '127.0.0.1',
    Stdlib::Port $statsd_port = 8125,
) {
    include ::webperf

    require_package('python3-kafka')
    require_package('python3-yaml')
    require_package('python3-etcd')

    # This matches the version pinned in setup.py in performance/navtiming.
    # If changed here, it should be changed there, and vice-versa.
    # (See comments on https://gerrit.wikimedia.org/r/c/performance/navtiming/+/622531)
    apt::pin { 'python3-ua-parser':
        pin      => 'version 0.10.0*',
        package  => 'python3-ua-parser',
        priority => '1001',
        before   => Package['python3-ua-parser'],
    }
    package { 'python3-ua-parser':
        ensure => present,
    }

    scap::target { 'performance/navtiming':
        service_name => 'navtiming',
        deploy_user  => 'deploy-service',
    }

    systemd::unit { 'navtiming':
        ensure  => present,
        # uses $statsd_host, $statsd_port, $kafka_brokers
        content => template('webperf/navtiming.systemd.erb'),
        restart => true,
    }

    service { 'navtiming':
        ensure   => running,
        provider => systemd,
    }

    base::service_auto_restart { 'navtiming': }
}
