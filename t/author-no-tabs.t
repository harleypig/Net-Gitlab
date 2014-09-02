
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = ( { { join( ",\n", map { "    '" . $_ . "'" } map { s/'/\\'/g; $_ } sort @filenames ) } } );

notabs_ok( $_ ) foreach @files;
done_testing;
