use strict;
use warnings;
use Test::More;
use Net::CouchDB;

if ( not $ENV{NET_COUCHDB_URI} ) {
    plan skip_all => 'Please set NET_COUCHDB_URI to a CouchDB instance URI';
    exit;
}
plan tests => 7;

# can we connect to the server?
my $couch = Net::CouchDB->new( $ENV{NET_COUCHDB_URI} );
isa_ok( $couch, 'Net::CouchDB', 'server object' );

# can we read the version number correctly?
my $version = $couch->version;
diag "CouchDB version $version";
like $version, qr/^\d+[.]\d+[.]\d+[a]\d+$/, 'version number';

# create a testing database
my $db_name = sprintf "net-couchdb-$$-%d", int( rand 100_000 );
my $db = $couch->create_db($db_name);
isa_ok $db, 'Net::CouchDB::DB', 'new database';

# is the new database included in the list of dbs?
my @matches = grep { $_->name eq $db_name } $couch->all_dbs;
cmp_ok scalar @matches, '==', 1, 'one new testing DB';
isa_ok $matches[0], 'Net::CouchDB::DB', 'new database (from list)';

# delete the test database so that we don't leave a mess
$db->delete;

# try connecting to something that's not a valid server
{
    my $couch = eval { Net::CouchDB->new('http://localhost:99999') };
    my $exception = $@;
    is( $couch, undef, 'no such server' );
    like( $exception, qr/Unable to connect to/, '... error message' );
}
