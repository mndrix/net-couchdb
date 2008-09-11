use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 4;

# insert a document and attach some content to it
{
    my $document = $couch->insert({ test => 'self' });
    my $attachment = $document->attach($0);   # attach ourself to the document
    isa_ok $attachment, 'Net::CouchDB::Attachment', 'attachment';

    # make sure the content is correct
    my $our_content = do { local $/; open my $fh, "<$0"; <$fh> };
    cmp_ok $attachment->length, '==', length($our_content), 'correct length';
    is $attachment->content, $our_content, 'content';
    is $attachment->content_type, 'text/plain', 'content type';
}


# TODO create a new document with an attachment already present
# TODO test $document->attachment('foo')
# TODO test $document->attachments;
