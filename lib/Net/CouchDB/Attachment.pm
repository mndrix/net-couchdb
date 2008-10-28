package Net::CouchDB::Attachment;
use strict;
use warnings;

use Net::CouchDB::Request;
use URI;

sub new {
    my ( $class, $args ) = @_;
    return bless {
        document => $args->{document},
        name     => $args->{name},
    }, $class;
}

sub document { shift->{document} }
sub name     { shift->{name}     }

sub length {
    my ($self) = @_;
    return $self->{length} if exists $self->{length};
    return length( $self->content );
}

sub content {
    my ($self) = @_;
    my $res = $self->request( 'GET', {
        description => 'get an attachment',
        200         => 'ok',
    });
    $self->{content_type} = $res->res->header('content-type');
    return $res->content;
}

sub content_type {
    my ($self) = @_;
    return $self->{content_type} if exists $self->{content_type};
    my $res = $self->request( 'HEAD', {
        description => 'get attachment headers',
        200         => 'ok',
    });
    return $self->{content_type} = $res->res->header('content-type');
}

sub ua { shift->document->ua }  # use the document's UserAgent

sub uri {
    my ($self) = @_;
    return URI->new_abs( $self->name , $self->document->uri );
}

1;

__END__

=head1 NAME

Net::CouchDB::Attachment - an attachment to a document

=head1 SYNOPSIS

    use Net::CouchDB;
    # do some stuff to connect to a database...
    
    my $document = $db->insert({ key => 'value' })
    my $attachment = $document->attach('file-name.txt');
    printf "The document is %d bytes long.\n", $attachment->length;

=head1 DESCRIPTION

A Net::CouchDB::Attachment object represents an attachment to a CouchDB
document.

=head1 METHODS

=head2 new

Generally speaking, users should not call this method directly.  Document
objects should be created by calling appropriate methods on a
L<Net::CouchDB::Document> object such as "attach".

=head2 attach( $filename )

Attach the contents of C<$filename> to the current document as an attachment.
If the file looks like it's text, the content type is C<text/plain>;
otherwise, the content type is C<application/octet-stream>.

=head2 document

Returns a L<Net::CouchDB::Document> object indicating the document with which
this attachment is associated.

=head2 name

Returns the attachment's name.  A document may only have one attachment with
a given name.

=head2 uri

Returns a L<URI> object representing the URI for this attachment.

=head2 content

Fetches the attachment from the server and returns the content.

=head2 content_type

Returns the content type of the attachment. If it hasn't been fetched (by
calling C<content>) a HEAD request will be done to get the content_type.

=head2 length

Returns the size of the attachment.

=head1 INTERNAL METHODS

These methods are primarily intended for internal use but documented here
for completeness.

=head2 ua

Returns the L<LWP::UserAgent> object used for making HTTP requests.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
