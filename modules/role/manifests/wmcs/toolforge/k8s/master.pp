class role::wmcs::toolforge::k8s::master {
    system::role { $name: }

    include ::profile::base::firewall
    include ::profile::toolforge::base
    include ::profile::toolforge::infrastructure
    include ::profile::toolforge::k8s::master
}
