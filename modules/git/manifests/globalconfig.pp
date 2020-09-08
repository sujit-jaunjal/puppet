class git::globalconfig {
  file { '/etc/gitconfig.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    recurse => true,
    purge   => true,
  }

  file { '/etc/gitconfig.d/00-header.gitconfig':
      ensure  => file,
      content => '# This file is managed by Puppet\n',
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      notify  => Exec['update-gitconfig'],
  }

  exec { 'update-gitconfig':
      command     => '/bin/cat /etc/gitconfig.d/*.gitconfig > /etc/gitconfig',
      creates     => '/etc/gitconfig',
      refreshonly => true,
  }
}
