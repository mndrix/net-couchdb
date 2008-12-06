package Net::CouchDB::ViewResult;
use warnings;
use strict;

use Net::CouchDB;
use Net::CouchDB::Request;
use Net::CouchDB::ViewResultRow;
use URI;

sub new {
    my $class = shift;
    my $args  = shift;
    my $json = Net::CouchDB->json;

    my %params = %$args;

    # searches by key
    if ( my $key = delete $params{key} ) {
        $key = $json->encode($key);
        $params{startkey} = $params{endkey} = $key;
    }

    my $self = bless {
        view   => delete $params{view},
        params => \%params,
        _pointer => 0,
    }, $class;

    # Note that this doesn't actually fetch the result; it only 
    # sets up the container for the result.
    # Fetching the data is done on demand ... (for better or worse)

    return $self;
}

sub view   { shift->{view}   }
sub params { shift->{params} }

sub count {
    my ($self) = @_;
    my $rows = $self->response->content->{rows};
    return scalar @$rows;
}

sub total_rows {
    my ($self) = @_;
    return $self->response->content->{total_rows};
}

sub first {
    my ($self) = @_;
    return if $self->count < 1;
    return Net::CouchDB::ViewResultRow->new({
        result => $self,
        row    => $self->response->content->{rows}[0],
    });
}

sub next {
    my ($self) = @_;

    # if the iterator has returned all results, reset it (similar to each())
    if ( $self->{_pointer} >= $self->count ) {
        $self->{_pointer} = 0;
        return;
    }

    return Net::CouchDB::ViewResultRow->new({
        result => $self,
        row    => $self->response->content->{rows}[ $self->{_pointer}++ ],
    });
}

sub response {
    my ($self) = @_;
    return $self->{response} if exists $self->{response};
    my $res = $self->request( 'GET', {
        description => 'retrieve the view',
        200         => 'ok',
        params      => $self->params,
    });
    $self->{_pointer} = 0;
    return $self->{response} = $res;
}

# use the design document's ua
sub ua { shift->view->design->ua }

sub uri { shift->view->uri }

1;

__END__

=head1 NAME

Net::CouchDB::ViewResult - the result of searching a view

=head1 SYNOPSIS

    my $rs = $view->search({ key => 'foo' });
    printf "There are %d rows\n", $rs->count;

    my $rs = $view->search({ count => 20, startkey_docid => 'abc' });
    my $doc = $rs->first;

=head1 DESCRIPTION

A L<Net::CouchDB::ViewResult> object represents the results of searching a
specific view.  Those results may be all rows from the view or it may be a
subset of those rows.  In general, a newly created ViewResult object lazily
represents the search results and does not actually query the CouchDB instance
until absolutely necessary.  The query usually happens the first time a
method is called on the ViewResult object.

=head1 METHODS

=head2 new

This method is only intended to be used internally.  The correct way to create
a new ViewResult object is to call L<Net::CouchDB::View/search>.

=head2 count

Returns the number of rows in the result.  This number will be less than
or equal to the number returned by L</total_rows>.

=head2 first

Returns a L<Net::CouchDB::ViewResultRow> object representing the first
row in the result.  If there are no rows in the result, it returns
C<undef>.

=head2 next

Returns the next L<Net::CouchDB::ViewResultRow> until there are no
more rows where it returns C<undef>.

=head2 search

This method is the workhorse of L<Net::CouchDB::ViewResult>.  It refines the
view results by further restricting which rows will be returned.  Under
typical usage, one starts with a ViewResult object that represents all the
rows of a view.  One then searches within those results to find specific rows
of interest.  For instance, if one is working with all the rows of a view

    my $result = $view->search();
    printf "The first of all rows has the key: %s", $result->first->key;

she may then refine those same results further

    my $cars = $result->search({ key => 'car' });
    printf "The first car row has the key: %s", $cars->first->key;

In your application, it's often convenient to return ViewResult objects and
let other parts of the application build up the results that they want.
Acceptable arguments to L</search> are described below.

The search arguments can be any arguments accepted by CouchDB's view API.  For
a complete list, see L<http://wiki.apache.org/couchdb/HttpViewApi>.  Arguments
of particular interest are document below.

=head3 key

Restricts the results to only those rows where the key matches the one given.
Searching ViewResults by key is very fast because of the way that CouchDB
handles indexes.

=head2 total_rows

Similar to L</count> but it returns the total number of rows that are
available in the View regardless whether those rows are available in
this result or not.

=head2 view

Returns a L<Net::CouchDB::View> object representing the view from which this
result is derived.

=head1 INTERNAL METHODS

These methods are intended for internal use.  They are documented here for
completeness.

=head2 params

Returns a hashref of CGI query parameters that will be used when querying
CouchDB to retrieve the view results.

=head2 response

Returns a L<Net::CouchDB::Response> object representing CouchDB's response to
our view query.  Calling this method will query the database if it hasn't been
queried yet.

=head2 ua

Returns the L<LWP::UserAgent> object used for making HTTP requests to the
database.

=head2 uri

Returns a L<URI> object indicating the URI of the view.  This is the same as
calling C<< $self->view->uri >>.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
