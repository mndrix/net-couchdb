use strict;
use warnings;
use Test::More;
use Net::CouchDB;

use lib 't/lib';
use Test::CouchDB;
my $db = setup_tests({ create_db => 1 });
plan tests => 3;

# This file contains tests for Net::CouchDB::db

# connect to the server
my $couch = Net::CouchDB->new( $ENV{NET_COUCHDB_URI} );

# try and fetch a database with a given name
{
    my $other_db = $couch->db( $db->name );
    isa_ok $other_db, 'Net::CouchDB::DB', 'the database';
}

# try to fetch a database that doesn't exist
{
    my $name = $db->name;
    $db->delete;
    my $other_db = $couch->db($name);
    isa_ok $other_db, 'Net::CouchDB::DB', 'getting a database is lazy';
    eval { $other_db->about };
    like $@, qr/\b404\b/, '... but it does not exist';
}
