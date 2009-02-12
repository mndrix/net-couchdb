use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 15;

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


# make sure that bulk() handles transactional failures correctly
@docs = eval {
    $couch->bulk({
        insert => [
            { _id => 'drei', fail => 'document with this ID already exists' },
        ],
        delete => [ $bar ],
    });
};
like $@, qr/409.*trying to operate on many/, 'conflict detected';
cmp_ok scalar @docs, '==', 0, 'no documents returned';
is $couch->document('drei')->{fail}, undef, 'document not inserted';
ok !$bar->is_deleted, 'bar was not deleted';
isa_ok $couch->document( $bar->id ), 'Net::CouchDB::Document','being safe';

# we shouldn't be allowed to update and delete a document in one go
# because CouchDB doesn't promise a consistent order for the inserts
# and deletes
TODO: {
    local $TODO = 'See https://issues.apache.org/jira/browse/COUCHDB-172';
    my $drei = $couch->document('drei');
    eval { $couch->bulk({ update => [ $drei ], delete => [ $drei ] }) };
    like $@, qr/'412'/, 'nonsense transactions are prevented';
}
