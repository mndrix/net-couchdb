use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::CouchDB;
my $couch = setup_tests({ create_db => 1 });
plan tests => 14;

# insert a document and attach some content to it
{
    my $document = $couch->insert({ test => 'self' });
    my $attachment;

    ok $attachment = $document->attach($0);   # attach ourself to the document
    isa_ok $attachment, 'Net::CouchDB::Attachment', 'attachment';

    # make sure the content is correct
    my $our_content = do { local $/; open my $fh, "<$0"; <$fh> };
    cmp_ok $attachment->length, '==', length($our_content), 'correct length';
    is $attachment->content, $our_content, 'content';
    is $attachment->content_type, 'text/plain', 'content type';

    # can we retrieve the attachment by name?
    my $retrieved = $document->attachment('document-attach.t');
    isa_ok $retrieved, 'Net::CouchDB::Attachment', 'retrieved by name';
    is $retrieved->content, $our_content, 'content';
    is $retrieved->content_type, 'text/plain', 'content type';

    # create an attachment with explicit content
    ok $attachment = $document->attach({
        name         => 'a2',
        content      => $our_content,
        content_type => 'application/perl'
    });
    is $attachment->content, $our_content, 'content 2';
    is $attachment->content_type, 'application/perl', 'content-type';

    # can we retrieve this attachment by name?
    $retrieved = $document->attachment('a2');
    isa_ok $retrieved, 'Net::CouchDB::Attachment', 'retrieved again by name';
    is $retrieved->content, $our_content, 'content';
    is $retrieved->content_type, 'application/perl', 'content type';
}

# TODO create a new document with an attachment already present
# TODO test $document->attachments;
