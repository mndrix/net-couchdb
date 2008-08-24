use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 6;

ok( !$couch->document_exists( "blah blah blah" ), 'nonexistent doc' );

# insert a document to work with
my $master = $couch->insert({ a => 'document' });
ok( $couch->document_exists( $master->id ), 'document exists' );
my $needle = $couch->document( $master->id );
isa_ok( $needle, 'Net::CouchDB::Document', 'a document' );
is( $needle->id, $master->id, 'document IDs match' );
is( $needle->rev, $master->rev, 'document revs match' );

# try retrieving a document that doesn't exist
$needle = $couch->document('not really there');
is $needle, undef, 'the document does not exist';
