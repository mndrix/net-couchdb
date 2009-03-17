use strict;
use warnings;
use Test::More;
use Net::CouchDB;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 9;

# Tests for Net::CouchDB::Document::update

# create a document
my $document = $couch->insert({ some => 'document' });
my $id = $document->id;

# the document starts out the way we created it
is_deeply { %$document }, { some => 'document' }, 'as it started';

# our local copy is changed, but the database is not
$document->{some} = 'change';
$document->{key}  = [ 'value' ];
is_deeply
    { %$document },
    { some => 'change', key => ['value'] },
    'changed locally';
my $refresh = $couch->document($id);
is_deeply { %$refresh }, { some => 'document' }, 'database is not changed';

# updating causes the changes to happen
$document->update;
$refresh = $couch->document($id);
is_deeply
    { %$document },
    { some => 'change', key => ['value'] },
    'still changed locally';
is_deeply
    { %$refresh },
    { some => 'change', key => ['value'] },
    'changed in the database';


# make sure that conflicting modifications cause an exception
$document->{key} = 'changed';
eval { $document->update };
is $@, '', 'first update succeeds';
$refresh->{key} = 'different';
eval { $refresh->update };
like $@, qr/Document update conflict/, 'conflicting change';

# completely replace the contents of the document
%$document = (
    one        => 1,
    two        => 2,
    three      => 3,
    translated => [qw( eins zwei drei )],
);
$document->update;
is_deeply
    { %$document },
    { one => 1, two => 2, three => 3, translated => [qw( eins zwei drei )] },
    'wholesale local replacement';
$refresh = $couch->document($id);
is_deeply
    { %$refresh },
    { one => 1, two => 2, three => 3, translated => [qw( eins zwei drei )] },
    'wholesale local replacement';
