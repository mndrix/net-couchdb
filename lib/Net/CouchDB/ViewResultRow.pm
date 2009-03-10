package Net::CouchDB::ViewResultRow;
use warnings;
use strict;

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = bless {
        result => $args->{result},
        row    => $args->{row},
    }, $class;
    return $self;
}

sub result { shift->{result} }
sub row    { shift->{row} }
sub key    { shift->row->{key} }
sub value  { shift->row->{value} }
sub id     { shift->row->{id} }
sub db     { shift->result->view->design->db }

sub document {
    my ($self) = @_;
    if ( $self->row->{doc} ) {
        my $class = $self->db->_document_class( $self->id );
        return $class->new({
            db   => $self->db,
            data => $self->row->{doc}
        });
    }

    return $self->db->document($self->id);
}

1;

__END__

=head1 NAME

Net::CouchDB::ViewResultRow - a single result row from searching a view

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

This method is intended for internal use.  To obtain a
L<Net::CouchDB::ViewResultRow> object, call methods such as
L<Net::CouchDB::ViewResult/first>.

=head2 document

Returns a L<Net::CouchDB::Document> object representing the document from
which this result row was derived.  If C<< include_docs => "true" >> was used
as a search parameter (see L<Net::CouchDB::ViewResult/search>, the document
object is returned without any additional HTTP requests.

=head2 id

Returns the DocID of the document that resulted in this row, which is the
unique identifier of that document in this database.

This is undefined for map+reduce queries.

=head2 key

Returns the key of this result row.  The key could be a single scalar value,
an arrayref or a hashref because CouchDB map functions can emit any
of those structures as a key.

=head2 result

Returns the L<Net::CouchDB::ViewResult> object of which this row is part.

=head2 value

Returns the value of this result row.  The value could be a single scalar
value, an arrayref or a hashref because CouchDB map functions can emit any of
those structures as values.

=head1 INTERNAL METHODS

=head2 db

Returns the L<Net::CouchDB::DB> object associated with this row.

=head2 row

Returns a hashref indicating the raw row data returned from CouchDB.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
