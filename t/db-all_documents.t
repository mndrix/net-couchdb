use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 8;

# a new database has no documents
{
    my @docs = $couch->all_documents;
    is_deeply( \@docs, [], 'no documents in a new database' );

    my $docs = $couch->all_documents;
    is_deeply( $docs, [], 'no documents in a new database: scalar' );
}

# insert a few documents
$couch->insert( { food => 'apple' } );
$couch->insert( { food => 'bacon' } );
$couch->insert( { food => 'cheese' } );
$couch->insert( { food => 'dessert' } );

# can we get the documents back out?
my @docs = $couch->all_documents;
isa_ok( $_, 'Net::CouchDB::Document', 'a document' ) for @docs;

# do they have the right values?
my @foods = sort map { $_->{food} } @docs;
is_deeply(
    \@foods,
    [qw( apple bacon cheese dessert )],
    'the right documents',
);

@docs = $couch->all_documents({limit => 2});
is scalar @docs, 2, "limit to two docs";


