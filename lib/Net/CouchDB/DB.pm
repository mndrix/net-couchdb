package Net::CouchDB::DB;
use strict;
use warnings;

use Net::CouchDB::Document;

sub new {
    my ( $class, $args ) = @_;
    my $couch = $args->{couch};
    my $name  = $args->{name};
    my $self = bless {
        couch => $couch,
        name  => $name,
    }, $class;

    # create the new database if needed
    if ( $args->{create} ) {
        my $res = $self->call( 'PUT', '' );
        my $code = $res->code;
        if ( $code == 201 ) {
            return $self;  # no need to check the content
        }
        elsif ( $code == 409 ) {
            die "A database named '$name' already exists\n";
        }
        else {
            my $uri = $self->couch->uri;
            my $details = $self->couch->json->decode( $res->content );
            my $error = ref $details ? $details->{reason} : 'unknown';
            die "CouchDB at $uri encountered the following error: $error\n";
        }
    }

    # TODO $self->call('GET', '') to verify that the DB exists
    # TODO the result of that query can be used for a new ->about
    # TODO which returns details about the database
    return $self;
}

sub about {
    my ($self) = @_;
    return $self->{about} if exists $self->{about};

    # no cached info, so fetch it from the server
    my $res = $self->call( 'GET' => '' );
    return $self->{about} = $self->couch->json->decode( $res->content )
        if $res->code == 200;
    die "CouchDB at " . $self->couch->uri . " encountered a problem "
      . "when retrieving database information for the database "
      . $self->name;
}

# quick and easy methods related to document metadata
sub document_count         { shift->about->{doc_count}     }
sub deleted_document_count { shift->about->{doc_del_count} }
sub disk_size              { shift->about->{disk_size}     }

sub delete {
    my ($self) = @_;
    my $res = $self->call( 'DELETE', '' );
    my $code = $res->code;
    return if $code == 202;
    die "The database " . $self->name . " does not exist on the CouchDB "
      . "instance at " . $self->couch->uri . "\n"
      if $code == 404;
    die "Unknown status code '$code' while trying to delete the database "
      . $self->name . " from the CouchDB instance at "
      . $self->couch->uri ;
}

sub insert {
    my ($self, $data) = @_;
    die "insert() called without a hashref argument" if ref($data) ne 'HASH';
    my $id = $data->{_id};
    my ($method, $uri) = defined $id ? ('PUT', "/$id") : ('POST', '/');
    my $res = $self->call( $method, $uri, $data );
    if ( $res->code == 201 ) {  # it worked, so build the object
        my $body = $self->couch->json->decode( $res->content );
        my ( $id, $rev ) = @{$body}{ 'id', 'rev' };
        return Net::CouchDB::Document->new( $self, $id, $rev );
    }
    my $code = $res->code;
    die "Unknown status code '$code' while trying to delete the database "
      . $self->name . " from the CouchDB instance at "
      . $self->couch->uri;
}

sub call {
    my ( $self, $method, $partial_uri, $content ) = @_;
    $partial_uri = $self->name . $partial_uri;
    return $self->couch->call( $method, $partial_uri, $content );
}

sub couch {
    my ($self) = @_;
    return $self->{couch};
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

1;

__END__

=head1 NAME

Net::CouchDB::DB - a single CouchDB database

=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)


=head1 METHODS

=head2 new(\%args)

 Named arguments:
    $couch  - required Net::CouchDb object
    $name   - required database name
    $create - optional boolean: should the database be created?

Creates a new L<Net::CouchDB::DB> object representing a database named
C<$name> residing on the C<$couch> server (a L<Net::CouchDB> object).
If C<$create> is true, the database is assumed not to exist and is created
on the server.  If attempts to create the database fail, an exception
is thrown.

=head2 about

Returns a hashref with information about this database.  If the server cannot
provide the information, an exception is thrown.  This method provides raw
access to the details that a CouchDB server provides about a database.  It's
generally better to use the wrapper methods (below) than to access this
method's return value directly.  Using the wrapper methods insulates one's
program from changes to the format of CouchDB's response format.  Wrapper
methods include
L</deleted_document_count>,
L</disk_size>,
L</document_count> and
L</name>.

=head2 delete

Deletes the database from the CouchDB server.  All associated documents
are also deleted.

=head2 deleted_document_count

Returns the number of deleted documents whether or not those documents
have been removed by compaction or are still present on disk.

=head2 disk_size

Returns the size of the current database on disk.

=head2 document_count

Returns the number of non-deleted documents present in the database.

=head2 insert(\%data)

Creates a new document in the database with the data in hashref C<\%data>.  On
success, returns a new L<Net::CouchDB::Document> object.  On failure, throws
an exception.

=head2 name

Returns this database's name.

=head1 INTERNAL METHODS

These methods are primarily intended for internal use but documented here
for completeness.

=head2 call($method, $relative_uri [,$content] )

Identical to L<Net::CouchDB/call> but C<$relative_uri> is relative
to the base URI of the current database.

=head2 couch

Returns a L<Net::CouchDB> object representing the server in which this
database resides.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
