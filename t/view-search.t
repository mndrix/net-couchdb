use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 26;

# put some documents into the database
$couch->insert(
    { number => 1, letter => 'a' },
    { number => 2, letter => 'b' },
    { number => 2, letter => 'c' },
    { number => 3, letter => 'd' },
    { number => 3, letter => 'e' },
    { number => 3, letter => 'f' },
);

# create a new design document w/o any views
my $design = $couch->insert({ _id => '_design/example' });
my $view = $design->add_view('numbers', {
    map => q{
        function (doc) {
            var num = doc.number;
            if      ( num == 1 ) emit( 'one',   doc.letter );
            else if ( num == 2 ) emit( 'two',   doc.letter );
            else if ( num == 3 ) emit( 'three', doc.letter );
        }
    },
});

my $view_letters = $design->add_view('letters', {
    map => q{
        function (doc) {
            emit(doc.letter, null);
        }
    },
});

# search for a single key
my $rs = $view->search({ key => 'one' });
isa_ok $rs, 'Net::CouchDB::ViewResult', 'search for "one"';
cmp_ok $rs->count, '==', 1, '… correct count';
cmp_ok $rs->total_rows, '==', 6, '… correct total row count';
my $row = $rs->first;
isa_ok $row, 'Net::CouchDB::ViewResultRow', '… first row';
is $row->key, 'one', '… first row key';
is $row->value, 'a', '… first row value';
my $doc = $row->document;
isa_ok $doc, 'Net::CouchDB::Document';

# search with included documents
$rs = $view->search({ key => 'one', include_docs => 'true' });
isa_ok $rs, 'Net::CouchDB::ViewResult', 'search for "one"';
cmp_ok $rs->count, '==', 1, '… correct count';
cmp_ok $rs->total_rows, '==', 6, '… correct total row count';
$row = $rs->first;
isa_ok $row, 'Net::CouchDB::ViewResultRow', '… first row';
is $row->key, 'one', '… first row key';
is $row->value, 'a', '… first row value';
is_deeply $row->document, $doc, '… same document result';

# search for a single key with key as is
$rs = $view->search({ key => \'"one"' });
isa_ok $rs, 'Net::CouchDB::ViewResult', 'search for "one"';
cmp_ok $rs->count, '==', 1, '… correct count';
$row = $rs->first;
isa_ok $row, 'Net::CouchDB::ViewResultRow', '… first row';
is $row->key, 'one', '… first row key';
is $row->value, 'a', '… first row value';
isa_ok $row->document, 'Net::CouchDB::Document';


$rs = $view_letters->search({ limit => 2, descending => JSON::true });

my @rows;
while (my $row = $rs->next) {
    push @rows, $row->key;
}

cmp_ok $rs->count, '==', 2, 'got the right row count';
is_deeply \@rows, [ 'f', 'e' ], 'and the right results';

#search for range of keys

$rs = $view_letters->search( { startkey=> 'b', endkey=> 'd' });

@rows=();
while (my $row = $rs->next) {
    push @rows, $row->key;
}

cmp_ok $rs->count, '==', 3, 'got the right row count';
is_deeply \@rows, [ 'b', 'c',  'd' ], 'and the right results';

#keys as json strings;
$rs = $view_letters->search( { startkey=> \'"b"', endkey=> \'"d"' });

@rows=();
while (my $row = $rs->next) {
    push @rows, $row->key;
}

cmp_ok $rs->count, '==', 3, 'got the right row count';
is_deeply \@rows, [ 'b', 'c',  'd' ], 'and the right results';
