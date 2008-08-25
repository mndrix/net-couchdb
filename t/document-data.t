use strict;
use warnings;
use Test::More;
use Net::CouchDB;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 2;

# Tests for Net::CouchDB::Document data() method

# create a document
my $document = $couch->insert({ some => 'document' });
my $id = $document->id;

# do we have the right data?
my $data = $document->data();
is_deeply $data, { some => 'document' }, 'correct data';

# is it the same structure as returned by overloading?
$data->{things} = ['one', 'two'];
is_deeply \%$document, {
    some   => 'document',
    things => [qw( one two )],
}, 'same as overloaded hashref';
