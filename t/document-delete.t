use strict;
use warnings;
use Test::More;
use Net::CouchDB;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 3;

# Tests for Net::CouchDB::Document::delete

# create a document
my $document = $couch->insert({ some => 'document' });
my $id = $document->id;

# the document exists before deletion
my $d = $couch->document($id);
isa_ok $d, 'Net::CouchDB::Document', 'before deletion';

# the document is gone after deletion
$document->delete;
$d = $couch->document($id);
is $d, undef, 'missing after deletion';

# try to delete again throws an exception
eval { $document->delete };
like $@, qr/412.* deleting/, 'double delete exception';
