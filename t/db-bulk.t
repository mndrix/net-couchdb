use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 9;

# create some documents to work with
my $foo = $couch->insert({ foo => 'bar' });
my $bar = $couch->insert({ bar => 'baz' });
$bar->{bar} = 'this is a change';
my $bar_original_rev = $bar->rev;

# bulk insert, delete and update the documents
ok !$foo->is_deleted, 'foo has not been deleted yet';
my @docs = $couch->bulk({
    insert => [
        { first  => 1 },
        { second => 2 },
        { third  => 3, _id => 'drei' },
    ],
    delete => [ $foo ],
    update => [ $bar ],
});
cmp_ok scalar @docs, '==', 3, 'only inserted documents are returned';
is $docs[0]{first},  '1', 'first bulk document';
is $docs[1]{second}, '2', 'second bulk document';
is $docs[2]{third},  '3', 'third bulk document';
is $docs[2]->id, 'drei', 'explicit document id';
ok $foo->is_deleted, 'foo was deleted';
is $bar->{bar}, 'this is a change', 'bar was updated';
isnt $bar->rev, $bar_original_rev, 'bar has a new revision';
