use strict;
use warnings;
use Test::More;
use Net::CouchDB;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 2;

# Tests for Net::CouchDB::Document overloading

# create a document
my $document = $couch->insert({ some => 'document' });
my $id = $document->id;

# try using it in a few different contexts
is $document->{some}, 'document', 'as a hashref';
ok !!$document, 'as a boolean';
