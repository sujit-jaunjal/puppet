# Temporary solution until someone has input about what to do with base::firewall
class profile::base::firewall (
    Array[Stdlib::IP::Address] $monitoring_hosts = hiera('monitoring_hosts', []),
    Array[Stdlib::IP::Address] $cumin_masters = hiera('cumin_masters', []),
    Array[Stdlib::IP::Address] $bastion_hosts = hiera('bastion_hosts', []),
    Array[Stdlib::IP::Address] $cache_hosts = hiera('cache_hosts', []),
    Array[Stdlib::IP::Address] $kafka_brokers_main = hiera('kafka_brokers_main', []),
    Array[Stdlib::IP::Address] $kafka_brokers_analytics = hiera('kafka_brokers_analytics', []),
    Array[Stdlib::IP::Address] $kafka_brokers_jumbo = hiera('kafka_brokers_jumbo', []),
    Array[Stdlib::IP::Address] $kafka_brokers_logging = hiera('kafka_brokers_logging', []),
    Array[Stdlib::IP::Address] $zookeeper_hosts_main = hiera('zookeeper_hosts_main', []),
    Array[Stdlib::IP::Address] $hadoop_masters = hiera('hadoop_masters', []),
    Array[Stdlib::IP::Address] $druid_public_hosts = hiera('druid_public_hosts', []),
    Array[Stdlib::IP::Address] $mysql_root_clients = hiera('mysql_root_clients', []),
    Array[Stdlib::IP::Address] $deployment_hosts = hiera('deployment_hosts', []),
) {
    class { '::base::firewall':
        monitoring_hosts        => $monitoring_hosts,
        cumin_masters           => $cumin_masters,
        bastion_hosts           => $bastion_hosts,
        cache_hosts             => $cache_hosts,
        kafka_brokers_main      => $kafka_brokers_main,
        kafka_brokers_analytics => $kafka_brokers_analytics,
        kafka_brokers_jumbo     => $kafka_brokers_jumbo,
        kafka_brokers_logging   => $kafka_brokers_logging,
        zookeeper_hosts_main    => $zookeeper_hosts_main,
        hadoop_masters          => $hadoop_masters,
        druid_public_hosts      => $druid_public_hosts,
        mysql_root_clients      => $mysql_root_clients,
        deployment_hosts        => $deployment_hosts,
    }
}
