use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 16;

# create a new design document w/o any views
{
    my $design = $couch->insert({ _id => '_design/empty' });
    my @views = $design->views;
    is_deeply \@views, [], 'no views';
    eval { $design->view('foo') };
    like $@, qr/'empty' has no views/, 'exception for a single view';
}

{
    my $design = $couch->document('_design/empty');
    isa_ok( $design, 'Net::CouchDB::DesignDocument', 'a design document' );
}

# create a design document with a single view
{
    my $design = $couch->insert({
        _id => '_design/small',
        views => {
            single => {},
        },
    });
    my $views = $design->views;
    cmp_ok scalar @$views, '==', 1, 'only one view';
    isa_ok $views->[0], 'Net::CouchDB::View', '… and it';
    is $views->[0]->name, 'single', '… and has the correct name';

    # accessing the view by name
    my $single = $design->view('single');
    isa_ok $single, 'Net::CouchDB::View', 'single view by name';
    is $single->name, 'single', '… and we even got the right one';

    # accessing a non-existent view by name
    eval { $design->view('not-here') };
    like $@, qr/'small' has no view named 'not-here'/, 'missing view by name';

    # does the view know about its design document?
    is $views->[0]->design->id, $design->id, 'design-view relation';
}

# create a design document with multiple views
{
    my $design = $couch->insert({
        _id => '_design/medium',
        views => {
            first  => {map => "function(doc) {}"},
            second => {map => "function(doc) { emit(doc.food, {}) }"},
        },
    });
    my @views = $design->views;
    cmp_ok scalar @views, '==', 2, 'two views';
    isa_ok $views[0], 'Net::CouchDB::View', '… one';
    isa_ok $views[1], 'Net::CouchDB::View', '… the other';
    is_deeply
        [ sort map { $_->name } @views ],
        [ 'first', 'second' ],
        '… correct names';

    $couch->insert( { food => 'apple' }, { food => 'bacon' },
                    { food => 'cheese' }, { food => 'dessert' }
                  );

    my $count = $views[1]->search->count;
    is $count, 4, "four docs";

    $count = $views[1]->search({ limit => 2 })->count;
    is $count, 2, "two docs with count parameter";

}
