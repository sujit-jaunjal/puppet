class profile::dumps::web::xmldumps_fallback(
    $do_acme = hiera('do_acme'),
) {
    class { '::dumpsuser': }

    class {'::dumps::web::xmldumps':
        do_acme          => $do_acme,
        datadir          => '/data/xmldatadumps',
        publicdir        => '/data/xmldatadumps/public',
        otherdir         => '/data/xmldatadumps/public/other',
        htmldumps_server => 'francium.eqiad.wmnet',
        xmldumps_server  => 'dumps.wikimedia.org',
        webuser          => 'dumpsgen',
        webgroup         => 'dumpsgen',
    }
}
