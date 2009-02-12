use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 6;

# insert a document to work with
my @docs = $couch->insert({ a => 1 }, { a => 2 }, { a => 3 });
$couch->insert({ d => 4 });

my @ids = sort map { $_->id } @docs;
my @needles = $couch->documents( @ids );
is( scalar(@needles), 3, 'count of fetching objects is 3' );
isa_ok( $_ , 'Net::CouchDB::Document', 'a document' ) foreach @needles;

my @nids = sort map { $_->id } @needles;
is_deeply \@ids, \@nids, 'fetching exactly that documents';

my @values = sort map { $_->{a} } @needles;
is_deeply [ 1..3 ], \@values, 'got the right content';

