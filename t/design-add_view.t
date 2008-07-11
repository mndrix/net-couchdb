use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 3;

# create a new design document w/o any views
my $design = $couch->insert({ _id => '_design/report' });

# and add a view to it
my $view = $design->add_view( 'first', {} );
isa_ok $view, 'Net::CouchDB::View', 'first view';

# can we also get the view from the design document?
isa_ok $design->view('first'), 'Net::CouchDB::View', 'first view again';

# adding another one with the same name is bad
eval { $design->add_view( 'first', {} ) };
like $@, qr/view named 'first' already/, 'prohibit duplicates';
