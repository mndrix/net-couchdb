use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 8;

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
