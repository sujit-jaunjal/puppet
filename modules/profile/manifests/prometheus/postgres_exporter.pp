class profile::prometheus::postgres_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    class { 'prometheus::postgres_exporter': }

    ferm::service { 'prometheus-postgres-exporter':
        proto  => 'tcp',
        port   => '9187',
        srange => $ferm_srange,
    }
}
