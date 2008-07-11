use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 3;

# create a new design document w/o an explicit language
{
    my $design = $couch->insert({ _id => '_design/implicit' });
    is $design->language, 'javascript', 'default design language (implicit)';
}

# explicitly specify the default language
{
    my $design = $couch->insert({
        _id      => '_design/js',
        language => 'javascript',
    });
    is $design->language, 'javascript', 'default design language (explicit)';
}

# explicitly specify some other language
{
    my $design = $couch->insert({
        _id      => '_design/pl',
        language => 'perl',
    });
    is $design->language, 'perl', 'some other design language';
}
