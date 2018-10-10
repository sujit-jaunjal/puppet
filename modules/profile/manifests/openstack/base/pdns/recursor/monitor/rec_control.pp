class profile::openstack::base::pdns::recursor::monitor::rec_control {

    sudo::user { 'diamond_sudo_for_pdns_recursor':
        user       => 'diamond',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/rec_control get-all'],
    }

    sudo::user { 'prometheus_sudo_for_pdns_recursor':
        user       => 'prometheus',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/rec_control get-all'],
    }
}
