package Net::CouchDB::Document;
use strict;
use warnings;

use Net::CouchDB::Request;
use Storable qw( dclone );
use URI;
use overload '%{}' => '_public_data', fallback => 1;

# a Document object is a blessed arrayref to avoid hash
# dereferencing problems
use constant _db     => 0;
use constant _id     => 1;  # document ID
use constant _rev    => 2;  # revision on which this document is based
use constant _data   => 3;  # the original data from the server
use constant _public => 4;  # public copy of 'data'
use constant _deleted => 5; # is this document deleted in the database?
sub new {
    my ($class, $args) = @_;

    my $self = bless [], $class;
    $self->[_db]     = $args->{db};
    $self->[_id]     = $args->{id}  || $args->{data}{_id};
    $self->[_rev]    = $args->{rev} || $args->{data}{_rev};
    $self->[_data]   = $args->{data};
    $self->[_public] = undef;
    $self->[_deleted] = 0;
    return $self;
}

sub db  { shift->[_db]  }
sub id  { shift->[_id]  }
sub rev { shift->[_rev] }
sub is_deleted { shift->[_deleted] }

sub delete {
    my ($self) = @_;
    my @deleted = $self->db->bulk({ delete => [$self] });
    return;
}

sub ua { shift->db->ua }  # use the db's UserAgent

sub uri {
    my ($self) = @_;
    return URI->new_abs( $self->id , $self->db->uri );
}

sub update {
    my ($self) = @_;
    $self->db->bulk({ update => [ $self ] });
    return;
}

# this method lets us pretend that we're really a hashref
sub _public_data {
    my ($self) = @_;

    if ( not defined $self->[_public] ) {
        if ( not defined $self->[_data] ) {
            my $res = $self->request( 'GET', {
                description => 'get a document',
                200         => 'ok',
            });
            $self->[_data] = $res->content;
        }
        $self->[_public] = dclone $self->[_data];
        delete $self->[_public]->{_id};
        delete $self->[_public]->{_rev};
    }

    # return the copy so that users can modify it at will
    return $self->[_public];
}

# after we've been updated or deleted, someone calls this to let
# us know about our new standing in the database
sub _you_are_now {
    my ( $self, $args ) = @_;
    my $rev = $args->{rev} or die "I am now what? Give me a rev dangit!\n";
    $self->[_rev]     = $rev;
    $self->[_deleted] = $args->{deleted};
    $self->[_data]    = undef;  # our old data is no good
    $self->[_public]  = undef;  # same with our public data
    return;
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
    $document->{actor} = 'James Dean';
    $document->update;

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

=head2 delete

Deletes the document from the database.  Throws an exception if there is an
error while deleting.

=head2 id

Returns the document ID for this document.  This is the unique identifier for
this document within the database.

=head2 is_deleted

Returns a true value if this document has been deleted from the database.
Otherwise, it returns false.

=head2 rev

Returns the revision name on which this document is based.  It's possible that
the document has been modified since it was retrieved from the database.  In
such a case, the data in the document may not represent what is currently
stored in the database.

=head2 update

Stores any changes to the document into the database.  If the changes
cause a conflict, an exception is thrown.  One may treat a Document
object like a hashref and make changes to it however those changes are not
stored in the database until C<update> is called.

=head2 uri

Returns a L<URI> object representing the URI for this document.

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
