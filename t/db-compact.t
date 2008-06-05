use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 2;

# insert a few documents and delete one
my $apple   = $couch->insert( { a => 'apple' } );
my $bacon   = $couch->insert( { b => 'bacon' } );
my $cheese  = $couch->insert( { c => 'cheese' } );
my $dessert = $couch->insert( { d => 'dessert' } );

# test the synchronous API
{
    $apple->delete;
    my $starting_size = $couch->disk_size;
    $couch->compact;
    my $ending_size = $couch->disk_size;
    cmp_ok( $starting_size, '>', $ending_size, 'size reduction' );
}

# test the asynchronous API
{
    $bacon->delete;
    my $starting_size = $couch->disk_size;
    $couch->compact({ async => 1 });
    sleep 1 while $couch->is_compacting;
    my $ending_size = $couch->disk_size;
    cmp_ok( $starting_size, '>', $ending_size, 'async: size reduction' );
}
