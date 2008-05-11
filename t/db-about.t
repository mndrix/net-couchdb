use strict;
use warnings;
use Test::More;
use Net::CouchDB;

use lib 't/lib';
use Test::CouchDB;
my $db = setup_tests({ create_db => 1 });
plan tests => 4;

# This file contains tests for Net::CouchDB::DB::about
my $about = $db->about;
isa_ok $about, 'HASH', 'database metadata';

# check some of the methods that depend on the metadata
cmp_ok $db->document_count, '==', 0, 'no documents yet';
cmp_ok $db->deleted_document_count, '==', 0, 'no deleted documents yet';
like   $db->disk_size, qr/^\d+$/, 'disk size is reasonable';
