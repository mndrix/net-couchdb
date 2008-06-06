use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 7;

# TODO delete this once done testing
my $foo = $couch->insert({ foo => 'bar' });
warn "foo is " . $foo->id . '/' . $foo->rev . "\n";
my $bar = $couch->insert({ bar => 'baz' });
warn "bar is " . $bar->id . '/' . $bar->rev . "\n";
$bar->{bar} = 'this is a change';

# bulk insert
my @docs = $couch->bulk({
    insert => [
        { first  => 1 },
        { second => 2 },
        { third  => 3, _id => 'drei' },
    ],
    delete => [ $foo ],
    update => [ $bar ],
});
is $docs[0]{first},  '1', 'first bulk document';
is $docs[1]{second}, '2', 'second bulk document';
is $docs[2]{third},  '3', 'third bulk document';
is $docs[2]->id, 'drei', 'explicit document id';

# bulk insert, delete and update
my ( $first, $second, $third ) = @docs[ 0, 1 ];
my $third_rev = $third->rev;
$third->{third} = '3.0';
@docs = $couch->bulk({
    insert => [ { fourth => 4 } ],
    delete => [ $first, $second ],
    update => [ $third ],
});
cmp_ok scalar @docs, 2, 'document count after a bulk insert/update/delete';
is $docs[0]{fourth}, '4', 'fourth bulk document';
isnt $docs[1]->rev, $third_rev, 'third has a new revision';
