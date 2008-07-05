package Net::CouchDB::Response;
use warnings;
use strict;
use Net::CouchDB;

sub new {
    my ($class, $ua_res) = @_;
    die "A response object must be provided" if not $ua_res;
    return bless { response => $ua_res }, $class;
}

sub response { shift->{response} }
sub res      { shift->{response} }

sub code { shift->response->code }

sub json { Net::CouchDB->json }

sub content {
    my ($self) = @_;
    my $ct = $self->response->content_type;
    return $self->json->decode( $self->response->content )
        if $ct eq 'application/json';
    return $self->response->content;
}

1;

__END__

=head1 NAME

Net::CouchDB::Response - a CouchDB response to an HTTP request


=head1 SYNOPSIS

    return Net::CouchDB::Response->new( $self->ua->request($req) );
 
=head1 DESCRIPTION

This module is intended to be used internally by Net::CouchDB.  It's
documented here for completeness.

=head1 METHODS

=head2 new($ua_res)

C<$ua_res> should be a response object as returned by
L<LWP::UserAgent/request>

=head2 content

If the response had a JSON content type, returns a Perl data structure
representing the data encoded in the JSON.  Otherwise, returns the raw
response body.

=head2 code

Returns the HTTP status code from this response.

=head2 json

A shortcut for calling L<Net::CouchDB/json>.

=head2 res

A shortcut for L</response>.

=head2 response

Returns the original response object from L<LWP::UserAgent> that was used to
create this object.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-net-couchdb at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-CouchDB>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::CouchDB

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-CouchDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-CouchDB>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-CouchDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-CouchDB>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
