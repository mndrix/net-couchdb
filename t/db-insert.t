use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 17;

# insert and let CouchDB assign a document ID
{
    my $document = $couch->insert({ foo => 'bar' });
    isa_ok $document, 'Net::CouchDB::Document', 'new document w/o an ID';
    ok $document->id, 'server-generated ID';
    ok $document->rev, 'document revision';
    is_deeply \%{$document}, { foo => 'bar' }, 'content is right';
}

# inserting with an explicit document ID
{
    my $document = $couch->insert({ _id => '42', etc => ['value'] });
    isa_ok $document, 'Net::CouchDB::Document', 'new document with an ID';
    is $document->id, '42', 'client-supplied ID';
    ok $document->rev, 'document revision';
    is_deeply \%{$document}, { etc => ['value'] }, 'content is right';
}

# insert a couple documents at once (bulk insert)
{
    my @documents = $couch->insert(
        { _id => 8675309 },
        { _id => 7511111 },
    );
    my $document = shift @documents;
    isa_ok $document, 'Net::CouchDB::Document', 'bulk insert: 1';
    is $document->id, '8675309', '… id';
    ok $document->rev, '… rev';

    $document = shift @documents;
    isa_ok $document, 'Net::CouchDB::Document', 'bulk insert: 2';
    is $document->id, '7511111', '… id';
    ok $document->rev, '… rev';
}

# inserting a design document
{
    my $design = $couch->insert({
        _id => '_design/reports',
    });
    isa_ok $design, 'Net::CouchDB::DesignDocument', 'design document';
    is $design->id, '_design/reports', '… id';
    ok $design->rev, '… rev';
}
