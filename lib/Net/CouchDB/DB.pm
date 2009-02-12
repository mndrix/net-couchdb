package Net::CouchDB::DB;
use strict;
use warnings;

use JSON 2.0;
use URI;
use URI::Escape qw();
use Net::CouchDB::Request;
use Net::CouchDB::Document;
use Net::CouchDB::DesignDocument;
use Storable qw( dclone );

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
        $self->request('PUT', {
            description => "create a database named '$name'",
            201         => 'ok',
            412         => "A database named '$name' already exists",
            500         => {
                illegal_database_name => "Error creating database '$name'",
            },
        });
        return $self;  # errors would have caused an exception
    }

    return $self;
}

sub ua { shift->couch->ua }  # use couch's UserAgent

sub about {
    my $self = shift;
    my $args = shift || {};
    return $self->{about} if $args->{cached} and exists $self->{about};

    # no cached info, so fetch it from the server
    my $res = $self->request('GET', {
        description => 'fetch DB meta data',
        200         => 'ok',
    });
    return $self->{about} = $res->content;
}

# quick and easy methods related to document metadata
sub document_count         { shift->about(shift)->{doc_count}     }
sub deleted_document_count { shift->about(shift)->{doc_del_count} }
sub disk_size              { shift->about(shift)->{disk_size}     }

sub is_compacting {
    my ($self) = @_;
    return 1 if $self->about->{compact_running};
    return;
}

sub delete {
    my ($self) = @_;
    my $name = $self->name;
    my $res = $self->request('DELETE', {
        description => "delete the DB named $name",
        200         => 'ok',
        404         => "The database $name does not exist",
    });
    return;
}

sub compact {
    my $self = shift;
    my $args = shift || {};

    my $res = $self->request( 'POST', '_compact', {
        description => 'compact the DB named ' . $self->name,
        202         => 'ok',
    });
    return if $args->{async};
    sleep 1 while $self->is_compacting;
    return;
}

sub insert {
    my ($self, @documents) = @_;
    die "insert() called without any documents to insert" if @documents < 1;
    my $inserted = $self->bulk({ insert => \@documents });
    return $inserted->[0] if @documents == 1;
    return wantarray ? @$inserted : $inserted;
}

sub bulk {
    my ($self, $args) = @_;
    die "bulk() called without a hashref argument" if ref($args) ne 'HASH';
    my @docs;
    my %input_doc_ids;
    if ( my $hashes = $args->{insert} ) {
        for my $hash (@$hashes) {
            die "Only plain hashes may be bulk inserted\n"
              if ref($hash) ne 'HASH';
            # make numeric IDs into strings (as CouchDB requires)
            $hash->{_id} = '' . $hash->{_id} if exists $hash->{_id};
            push @docs, $hash;
        }
    }
    if ( my $docs = $args->{delete} ) {
        for my $doc (@$docs) {
            die "Only document objects may be bulk deleted\n"
              if not eval { $doc->isa('Net::CouchDB::Document') };
            push @docs, {
                _id => $doc->id,
                _rev => $doc->rev,
                _deleted => JSON::true,
            };
            $input_doc_ids{ $doc->id } = [ 'delete', $doc ];
        }
    }
    if ( my $docs = $args->{update} ) {
        for my $doc (@$docs) {
            die "Only document objects may be bulk updated\n"
              if not eval { $doc->isa('Net::CouchDB::Document') };
            my $copy = dclone { %$doc };
            $copy->{_id}  = $doc->id;
            $copy->{_rev} = $doc->rev;
            push @docs, $copy;
            $input_doc_ids{ $doc->id } = [ 'update', $doc ];
        }
    }
    my $res = $self->request( 'POST', '_bulk_docs', {
        description => 'operate on many documents',
        content     => { docs => \@docs },
        201         => 'ok',
    });

    my @inserted_docs;
    NEWREV:
    for my $new ( @{ $res->content->{new_revs} } ) {
        my ( $id, $rev ) = @{$new}{ 'id', 'rev' };
        if ( my $request = $input_doc_ids{$id} ) {  # update or delete
            my ($operation, $doc) = @$request;
            $doc->_you_are_now({
                rev     => $rev,
                deleted => $operation eq 'delete',
            });
            next NEWREV;
        }

        # it must have been an insert
        push @inserted_docs, $self->_document_class($id)->new({
            db  => $self,
            id  => $id,
            rev => $rev,
        });
    }
    return wantarray ? @inserted_docs : \@inserted_docs;
}

sub _document_class {
    my ( $self, $document_id ) = @_;
    return $document_id =~ m{^_design/}
      ? 'Net::CouchDB::DesignDocument'
      : 'Net::CouchDB::Document';
}

sub document_exists {
    my ($self, $document_id) = @_;
    die "document() called without a document ID" if not defined $document_id;
    my $res = $self->request( 'HEAD', URI::Escape::uri_escape($document_id), {
       description => 'fetch a document',
       404         => 'ok',
       200         => 'ok',
    });

    return $res->code != 404;
}

sub document {
    my ($self, $document_id) = @_;
    die "document() called without a document ID" if not defined $document_id;
    my $res = $self->request( 'GET', URI::Escape::uri_escape($document_id), {
       description => 'fetch a document',
       404         => 'ok',  # should this die instead?
       200         => 'ok',
    });
    return if $res->code == 404;    # there's no such document

    # all is well
    return $self->_document_class($document_id)->new({
        db   => $self,
        data => $res->content,
    });
}

sub all_documents {
    my ($self, $args) = @_;
    my $res = $self->request('GET', '_all_docs', {
        description => 'fetch all documents',
        200         => 'ok',
        params      => ($args || {}),
    });

    # all is well
    my @documents;
    for my $row ( @{ $res->content->{rows} } ) {
        push @documents, Net::CouchDB::Document->new({
            db  => $self,
            id  => $row->{id},
            rev => $row->{value}{rev},
        });
    }

    return wantarray ? @documents : \@documents;
}

sub couch {
    my ($self) = @_;
    return $self->{couch};
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

sub uri {
    my ($self) = @_;
    return URI->new_abs( $self->name . '/' , $self->couch->uri );
}

sub clear {
    my $self = shift;
    $self->delete;
    $self->couch->create_db($self->name);
}

sub documents {
    my ( $self, @document_ids ) = @_;
    die "documents() called without document IDs" if not @document_ids;
    my $res = $self->request(
        'POST',
        '_all_docs',
        {
            description => 'fetch some documents',
            content     => { keys => \@document_ids },
            404         => 'ok',                      # should this die instead?
            200         => 'ok',
            params      => { include_docs => 'true' },
        }
    );
    return if $res->code == 404;                      # there's no such document

    my @documents;
    for my $row ( @{ $res->content->{rows} } ) {
        push @documents, Net::CouchDB::Document->new({
            db   => $self,
            data => $row->{doc},
        });
    }
    return @documents if wantarray;
    return \@documents;
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
L</is_compact_running> and
L</name>.

An optional hashref of named arguments can be provided.  If the named argument
"cached" is true, a cached copy of the previous information is returned.
Otherwise, the information is fetched again from the server.


=head2 all_documents

Returns a list (or arrayref, depending on context) of
L<Net::CouchDB::Document> objects representing all the documents in the
database.

L</all_documents> accepts an optional hashref of arguments which is passed
directly to CouchDB.  This allows one to request the first N documents or to
sort the documents in a particular order.

=head2 bulk(\%args)

 Named arguments:
    @insert - an optional arrayref of hashes to insert into the database
    @delete - an optional arrayref of Document objects to delete
    @update - an optional arrayref of Document objects to update

This method performs bulk insert, update and/or delete operations with a
single request to the server.  Additionally, the changes are made atomically.
If one change fails, all changes fail together.  For each inserted hashref, a
new L<Net::CouchDB::Document> object is returned.  Documents which were
deleted will be modified in place so that the
L<Net::CouchDB::Document/is_deleted> method returns true.  Documents which
were updated are modified in place so that they're aware of their new values
in the database.

=head2 compact

Compacts the database to reduce size on disk.  This is done, in part, by
removing outdated document revisions.

An optional hashref of name arguments can be provided.  If the named argument
"async" is true, the method returns immediately.  In such a case, one must
check L</is_compact_running> to determine whether or not the compaction phase
is complete.  By default, this method waits until compaction is finished and
then returns.

=head2 delete

Deletes the database from the CouchDB server.  All associated documents
are also deleted.

=head2 deleted_document_count

Returns the number of deleted documents whether or not those documents
have been removed by compaction or are still present on disk.
Accepts the same arguments as L</about>.

=head2 disk_size

Returns the size of the current database on disk.
Accepts the same arguments as L</about>.

=head2 document($id)

Returns a single L<Net::CouchDB::Document> object representing the
document whose ID is C<$id>.  If the document does not exist, returns
C<undef>.

If C<$id> identifiers a design document (that is, C<$id> starts with
"_design/"), the resulting object will be a L<Net::CouchDB::DesignDocument>,
which is a subclass of L<Net::CouchDB::Document>.

=head2 documents(@ids)

Return a list (or arrayref, depending on context) of L<Net::CouchDB::Document>
objects representing the documents whose IDs are in C<@ids>.

=head2 document_exists($id)

Returns true if the document exists.

This method uses an HTTP C<HEAD> request to find out if the document exists,
and doesn't retrieve the document data at all.  It is particularly useful for
large documents.

=head2 document_count

Returns the number of non-deleted documents present in the database.
This includes design documents as well.
Accepts the same arguments as L</about>.

=head2 insert

Given a list of hashrefs, creates a new document in the database for each one.
On success, returns a list (or arrayref, depending on context) of
L<Net::CouchDB::Document> objects.  If a single hashref is given, a single
document is returned (not contexnt sensitive).  On failure, it throws an
exception.  Inserted documents may be assigned a specific document ID by
providing a "_id" key in the hashref.

Because this method is implemented in terms of L</bulk>, if a single document
is invalid, none of the documents are inserted.

=head2 is_compacting

Returns a true value if the database is currently running compaction.
Otherwise, it returns a false value.

=head2 name

Returns this database's name.

=head2 uri

Returns a L<URI> object representing the URI for this database.

=head1 INTERNAL METHODS

These methods are primarily intended for internal use but documented here
for completeness.

=head2 couch

Returns a L<Net::CouchDB> object representing the server in which this
database resides.

=head2 ua

Returns the L<LWP::UserAgent> object used for making HTTP requests.

=head2 clear

A convenience method to delete and recreate the database.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
