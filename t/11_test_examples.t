#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);

$ENV{AUTHOR_TESTING} or plan(
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.'
);

plan(tests => 2);

my @data = (
    {
        test   => '01_oo_style',
        path   => 'example',
        script => '01_oo_style.pl',
        params => '-I../lib -T',
        result => <<'EOT',
$hash_map = {
  'mail_address' => 'steffenw@example.com',
  'city' => 'Examplecity',
  'account' => 'STEFFENW',
  'street' => 'Examplestreet',
  'country_code' => 'DE',
  'name' => 'Steffen Winkler',
  'zip_code' => '01234',
  'mail_name' => 'Steffen Winkler'
};
EOT
    },
    {
        test   => '02_functional_style',
        path   => 'example',
        script => '02_functional_style.pl',
        params => '-I../lib -T',
        result => <<'EOT',
$hash_map = {
  'mail_address' => 'steffenw@example.com',
  'city' => 'Examplecity',
  'account' => 'STEFFENW',
  'street' => 'Examplestreet',
  'country_code' => 'DE',
  'name' => 'Steffen Winkler',
  'zip_code' => '01234',
  'mail_name' => 'Steffen Winkler'
};
EOT
    },
);

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&3};
    chdir($dir);
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}
