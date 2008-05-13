package Net::CouchDB::Document;
use strict;
use warnings;

use Storable qw( dclone );
use overload '%{}' => '_public_data', falback => 1;

# a Document object is a blessed arrayref to avoid hash
# dereferencing problems
use constant _db     => 0;
use constant _id     => 1;  # document ID
use constant _rev    => 2;  # revision on which this document is based
use constant _data   => 3;  # the original data from the server
use constant _public => 4;  # public copy of 'data'
sub new {
    my ( $class, $db, $id, $rev ) = @_;
    my $self = bless [], $class;
    $self->[_db]     = $db;
    $self->[_id]     = $id;
    $self->[_rev]    = $rev;
    $self->[_data]   = undef;
    $self->[_public] = undef;
    return $self;
}

sub db  { shift->[_db]  }
sub id  { shift->[_id]  }
sub rev { shift->[_rev] }

sub call {
    my ( $self, $method, $partial_uri, $content ) = @_;
    $partial_uri = '/' . $self->id . $partial_uri;
    return $self->db->call( $method, $partial_uri, $content );
}

sub _public_data {
    my ($self) = @_;

    if ( not defined $self->[_public] ) {
        my $res = $self->call( 'GET' => '' );
        my $code = $res->code;
        die "Unknown status code '$code' while trying to delete the database "
          . $self->name . " from the CouchDB instance at "
          . $self->db->couch->uri
          if $code != 200;
        $self->[_data] = $self->db->couch->json->decode( $res->content );
        $self->[_public] = dclone $self->[_data];
        delete $self->[_public]->{_id};
        delete $self->[_public]->{_rev};
    }

    # return the copy so that users can modify it at will
    return $self->[_public];
}

1;

__END__

=head1 NAME

Net::CouchDB::Document - a single CouchDB document

=head1 SYNOPSIS

    use Net::CouchDB;
    # do some stuff to connect to a database
    my $document = $db->insert({ key => 'value' })

    # access the values individually
    print "* $document->{key}\n";

    # or iterate over them
    while ( my ($k, $v) = each %$document ) {
        print "$k --> $v\n";
    }

    # $document is not really a hash, but it acts like one

=head1 DESCRIPTION

A Net::CouchDB::Document object represents a single document in the CouchDB
database.  It represent a document which is no longer physically available
from the database but which was once available.

=head1 METHODS

=head2 new( $db, $id, $rev )

Generally speaking, users should not call this method directly.  Document
objects should be created by calling appropriate methods on a
L<Net::CouchDB::DB> object such as "insert".

=head2 db

Returns a L<Net::CouchDB::DB> object indicating the database in which
this document is stored.

=head2 id

Returns the document ID for this document.  This is the unique identifier for
this document within the database.

=head2 rev

Returns the revision name on which this document is based.  It's possible that
the document has been modified since it was retrieved from the database.  In
such a case, the data in the document may not represent what is currently
stored in the database.

=head1 INTERNAL METHODS

These methods are primarily intended for internal use but documented here
for completeness.

=head2 call( $method, $relative_uri [,$content] )

Just like L<Net::CouchDB/call> but C<$relative_uri> is taken relative to
the current document's URI.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
