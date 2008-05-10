use strict;
use warnings;
use Test::More;
use Net::CouchDB;

use lib 't/lib';
use Test::CouchDB;
setup_tests();
plan tests => 4;

# This file contains tests for Net::CouchDB::create_db

# create a database
my $couch = Net::CouchDB->new( $ENV{NET_COUCHDB_URI} );
my $db_name = sprintf "net-couchdb-$$-%d", int( rand 100_000 );
my $db = $couch->create_db($db_name);
END { $db->delete if $db };  # clean up after ourself
isa_ok $db, 'Net::CouchDB::DB', 'new database';

# try and create a database with the same name
{
    my $failed = eval { $couch->create_db($db_name) };
    my $exception = $@;
    is $failed, undef, 'duplicate database name';
    like $exception, qr/A database named .* already exists/, '... exception';
}

# try to create a database with a malformed name
{
    eval { $couch->create_db('98765ABC') };
    my $exception = $@;
    diag($exception) if $ENV{DEBUG};
    like( $exception, qr/Error creating database/, 'invalid database name' );
}
