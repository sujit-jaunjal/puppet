# == Class: icinga::monitor::traffic
#
# Monitor Traffic
class icinga::monitor::traffic {
    monitoring::grafana_alert { 'varnish-http-requests':
    }
}
