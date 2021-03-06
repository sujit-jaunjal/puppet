# == Define: sudo::group
#
# Manages a sudo specification in /etc/sudoers.d.
#
# === Parameters
#
# [*privileges*]
#   Array of sudo privileges.
#
# [*group*]
#   User to which privileges should be assigned.
#   Defaults to the resource title.
#
# [*sudo_flavor*]
#   sudo flavor to require. Options are sudo or sudoldap.
#   Defaults to 'sudo'.
#
# === Examples
#
#  sudo::group { 'nagios_check_raid':
#    group       => 'nagios',
#    privileges => [
#      'ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check-raid'
#    ],
#  }
#
define sudo::group(
    Array[String]           $privileges  = [],
    Wmflib::Ensure          $ensure      = present,
    String                  $group       = $title,
    # lint:ignore:wmf_styleguide
    Enum['sudo','sudoldap'] $sudo_flavor = lookup('sudo_flavor', {default_value => 'sudo'}),
    # lint:endignore
) {
    if $sudo_flavor == 'sudo' or debian::codename::ge('buster') {
        require sudo
    } else {
        require sudo::sudoldap
    }

    $title_safe = regsubst($title, '\W', '-', 'G')
    $filename = "/etc/sudoers.d/${title_safe}"

    if $ensure == 'present' {
        file { $filename:
            ensure       => $ensure,
            owner        => 'root',
            group        => 'root',
            mode         => '0440',
            content      => template('sudo/sudoers.erb'),
            validate_cmd => '/usr/sbin/visudo -cqf %',
        }
    } else {
        file { $filename:
            ensure => $ensure,
        }
    }
}
