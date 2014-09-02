
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.006008
use Test::Spelling 0.12;
use { { $wordlist } };

{
  { $set_spell_cmd }
}
{
  { $add_stopwords }
}
all_pod_files_spelling_ok( qw( bin lib  ) );
{
  { $stopwords }
}
