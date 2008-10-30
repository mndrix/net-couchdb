use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 10;

ok( !$couch->document_exists( "blah blah blah" ), 'nonexistent doc' );

# insert a document to work with
my $master = $couch->insert({ a => 'document' });
ok( $couch->document_exists( $master->id ), 'document exists' );
my $needle = $couch->document( $master->id );
isa_ok( $needle, 'Net::CouchDB::Document', 'a document' );
is( $needle->id, $master->id, 'document IDs match' );
is( $needle->rev, $master->rev, 'document revs match' );

ok($master = $couch->insert({ _id => 'some/document', a => 'document /' }),
   "create 'some/document' doc");
ok( $couch->document_exists( 'some/document' ), 'document exists' );
ok( $needle = $couch->document( 'some/document' ), 'fetch document' );
is( $needle->{a}, 'document /', 'got the right document');

# try retrieving a document that doesn't exist
$needle = $couch->document('not really there');
is $needle, undef, 'the document does not exist';
