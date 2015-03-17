# == Class: role::eventlogging
#
# This role configures an instance to act as the primary EventLogging
# log processor for the cluster. The setup is described in detail on
# <https://wikitech.wikimedia.org/wiki/EventLogging>. End-user
# documentation is available in the form of a guide, located at
# <https://www.mediawiki.org/wiki/Extension:EventLogging/Guide>.
#
# There exist two APIs for generating events: efLogServerSideEvent() in
# PHP and mw.eventLog.logEvent() in JavaScript. Events generated in PHP
# are sent by the app servers directly to vanadium on UDP port 8421.
# JavaScript-generated events are URL-encoded and sent to our servers by
# means of an HTTP/S request to bits, which a varnishncsa instance
# forwards to vanadium on port 8422. These event streams are parsed,
# validated, and multiplexed into an output stream that is published via
# ZeroMQ on TCP port 8600. Data sinks are implemented as subscribers
# that connect to this endpoint and read data into some storage medium.
#
class role::eventlogging {
    include eventlogging

    if hiera('has_ganglia', true) {
        include role::eventlogging::monitoring
    }

    system::role { 'role::eventlogging':
        description => 'EventLogging',
    }

    # Event data flows through several processes that communicate with each
    # other via TCP/IP sockets. At the moment, all processing is performed
    # locally, but the work could be easily distributed across multiple hosts.
    $processor = '127.0.0.1'


    ## Data flow

    # Server-side events are generated by MediaWiki and sent to vanadium
    # on UDP port 8421, using wfErrorLog('...', 'udp://...'). vanadium
    # is specified as the destination in $wgEventLoggingFile, declared
    # in wmf-config/CommonSettings.php.

    eventlogging::service::forwarder { '8421':
        ensure => present,
        count  => true,
    }

    eventlogging::service::processor { 'server-side events':
        format => '%{seqId}d EventLogging %j',
        input  => "tcp://${processor}:8421",
        output => 'tcp://*:8521',
    }

    # Client-side events are generated by JavaScript-triggered HTTP/S
    # requests to //bits.wikimedia.org/event.gif?<event payload>.
    # A varnishncsa instance on the bits caches greps for these requests
    # and forwards them to vanadium on UDP port 8422. The varnishncsa
    # configuration is specified in <manifests/role/cache.pp>.

    eventlogging::service::forwarder { '8422':
        ensure => present,
    }

    eventlogging::service::processor { 'client-side events':
        format => '%q %{recvFrom}s %{seqId}d %t %h %{userAgent}i',
        input  => "tcp://${processor}:8422",
        output => 'tcp://*:8522',
    }

    # Parsed and validated client-side (Varnish-generated) and
    # server-side (MediaWiki-generated) events are multiplexed into a
    # single output stream, published on TCP port 8600.

    eventlogging::service::multiplexer { 'all events':
        inputs => [ "tcp://${processor}:8521", "tcp://${processor}:8522" ],
        output => 'tcp://*:8600',
    }

    ## MySQL / MariaDB

    # Log strictly valid events to the 'log' database on m4-master.

    include passwords::mysql::eventlogging    # RT 4752
    $mysql_user = $passwords::mysql::eventlogging::user
    $mysql_pass = $passwords::mysql::eventlogging::password
    $mysql_db = $::realm ? {
        production => 'm4-master.eqiad.wmnet/log',
        labs       => '127.0.0.1/log',
    }

    eventlogging::service::consumer { 'mysql-m4-master':
        input  => "tcp://${processor}:8600",
        output => "mysql://${mysql_user}:${mysql_pass}@${mysql_db}?charset=utf8",
    }


    ## Flat files

    # Log all raw log records and decoded events to flat files in
    # $log_dir as a medium of last resort. These files are rotated
    # and rsynced to stat1003 & stat1002 for backup.

    $log_dir = $::eventlogging::log_dir

    eventlogging::service::consumer {
        'server-side-events.log':
            input  => "tcp://${processor}:8421?raw=1",
            output => "file://${log_dir}/server-side-events.log";
        'client-side-events.log':
            input  => "tcp://${processor}:8422?raw=1",
            output => "file://${log_dir}/client-side-events.log";
        'all-events.log':
            input  => "tcp://${processor}:8600",
            output => "file://${log_dir}/all-events.log";
    }

    $backup_destinations = $::realm ? {
        production => [  'stat1002.eqiad.wmnet', 'stat1003.eqiad.wmnet' ],
        labs       => false,
    }

    if ( $backup_destinations ) {
        include rsync::server

        rsync::server::module { 'eventlogging':
            path        => $log_dir,
            read_only   => 'yes',
            list        => 'yes',
            require     => File[$log_dir],
            hosts_allow => $backup_destinations,
        }
    }


    ## Kafka / Hadoop

    include role::analytics::kafka::config

    $kafka_brokers = inline_template('<%= scope.lookupvar("role::analytics::kafka::config::brokers_array").join(",") %>')
    $kafka_cluster = $::role::analytics::kafka::config::kafka_cluster_name

    $kafka_topic_base_name = 'eventlogging'
    $kafka_topic_version = 0
    $kafka_topic = sprintf('%s-%02d', $kafka_topic_base_name, $kafka_topic_version)

    eventlogging::service::consumer { 'kafka':
        input  => "tcp://${processor}:8600",
        output => "kafka://${kafka_cluster}?brokers=${kafka_brokers}&topic=${kafka_topic}",
        # We are not currently using this data in Kafka or Hadoop, and Kafka is about
        # to undergo some production failover testing.  Disabling this for now.
        ensure => 'absent',
    }
}


# == Class: role::eventlogging::monitoring
#
# Provisions scripts for reporting state to monitoring tools.
#
class role::eventlogging::monitoring {
    include ::eventlogging::monitoring

    eventlogging::service::reporter { 'statsd':
        host => 'statsd.eqiad.wmnet',
    }

    nrpe::monitor_service { 'eventlogging':
        ensure        => 'present',
        description   => 'Check status of defined EventLogging jobs',
        nrpe_command  => '/usr/lib/nagios/plugins/check_eventlogging_jobs',
        require       => File['/usr/lib/nagios/plugins/check_eventlogging_jobs'],
        contact_group => 'admins,analytics',
    }
}


# == Class: role::eventlogging::graphite
#
# Keeps a running count of incoming events by schema in Graphite by
# emitting 'eventlogging.SCHEMA_REVISION:1' on each event to a StatsD
# instance.

# The consumer connects to the host in 'input' and outputs data to the
# host in 'output'. The output host should normally be statsd
#
# Includes process nanny alarm for graphite consumer

class role::eventlogging::graphite {
    include ::eventlogging::monitoring

    eventlogging::service::consumer { 'graphite':
        input  => 'tcp://vanadium.eqiad.wmnet:8600',
        output => 'statsd://statsd.eqiad.wmnet:8125',
    }

    # Generate icinga alert if the graphite consumer is not running.
    nrpe::monitor_service { 'eventlogging':
        ensure        => 'present',
        description   => 'Check status of defined EventLogging jobs on graphite consumer',
        nrpe_command  => '/usr/lib/nagios/plugins/check_eventlogging_jobs',
        require       => File['/usr/lib/nagios/plugins/check_eventlogging_jobs'],
        contact_group => 'admins,analytics',
    }

}
