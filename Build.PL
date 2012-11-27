use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name       => 'Hash::Map',
    license           => 'perl',
    dist_abstract     => 'Hash::Map - Manipulate hashes map like',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/Hash/Map.pm',
    requires          => {
        perl                   => '5.006',
        version                => 0,
        Carp                   => 0,
        Clone                  => 0,
        'Perl6::Export::Attrs' => 0,
        'Scalar::Util'         => 0,
        'Try::Tiny'            => 0,
    },
    build_requires => {
        'Test::More'        => 0, # dist Test-Simple
        'Test::NoWarnings'  => '1.03',
        'Test::Differences' => '0.60',
    },
    recommends => {
        # build
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 0,
    add_to_cleanup       => [ qw(
        META.yml *.bak *.gz Makefile.PL
    ) ],
)->create_build_script;
