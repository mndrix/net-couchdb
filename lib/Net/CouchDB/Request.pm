package Net::CouchDB::Request;
use warnings;
use strict;
use Encode;

BEGIN {
    our @ISA = 'Exporter';
    our @EXPORT = qw( request );
}

sub request {
    my $self         = shift;
    my $method       = shift;
    my $relative_uri = !ref( $_[0] ) ? shift() : '';
    my $args         = shift || {};

    my $uri = URI->new_abs( $relative_uri, $self->uri );
    $uri->query_form( $args->{params} ) if $args->{params};
    my $req = HTTP::Request->new( $method, $uri );
    $req->header( Accept => 'application/json' );

    # set the request headers, if specified
    while ( my ($header, $value) = each %{ $args->{headers} || {} } ) {
        $req->header( $header => $value );
    }

    # set the request body if specified
    if ( my $body = $args->{content} ) {
	my $content = ref $body ? Net::CouchDB->json->encode($body) : $body;
	if(utf8::is_utf8($content)) {
	    $content = encode_utf8($content);
	}
        $req->content( $content );
        $req->header('Content-Length' => length $req->content);
    }

    if ($ENV{DEBUG}) {
        warn "---- Request ----\n";
        warn $req->as_string;
    }
    my $res = Net::CouchDB::Response->new( $self->ua->request($req) );
    if ($ENV{DEBUG}) {
        warn "---- Response ----\n";
        warn $res->res->as_string;
    }
    my $code = $res->code;
    my $message = $args->{$code};
    if ( defined $message ) {
        return $res if $message eq 'ok';
        my $reason = eval { $res->content->{reason} } || 'unknown';
        $message = $message->{$reason} if $message and ref($message) eq 'HASH';
        if ($message) {
            return $res if $message eq 'ok';
        }
    }
    else {  # default HTTP status code behavior
        return $res if $code >= 200 && $code <= 299;
    }

    # falling through to here means there was an error
    my $description = $args->{description} || 'do something';
    $message ||= "Unknown status code '$code' while trying to $description";
    my $reason = eval { $res->content->{reason} } || 'unknown';
    die "$message. $method request to $uri: $reason\n";
}


1;

__END__

=head1 NAME

Net::CouchDB::Request - a mixin method for making HTTP requests


=head1 SYNOPSIS

    use Net::CouchDB::Request;
    # … do something to create a $self object
    my $res = $self->request( 'GET', 'some/thing' );
    print "Value: " . $res->content->{value} . "\n";
 
=head1 DESCRIPTION

This module is intended to be used internally by Net::CouchDB.  It exports
a mixin method L</request> that simplifies the handling of HTTP requests
to a CouchDB server.

=head1 REQUIRED METHODS

Any class that imports the L</MIXIN METHODS> below needs to implement these
methods on its own.

=head2 ua

Returns a L<LWP::UserAgent> object which should be used for making
HTTP requests.

=head2 uri

Returns a L<URI> object indicating the base URI against which relative URIs
should be resolved.

=head1 MIXIN METHODS

=head2 request

 Arguments:
    - $method
    - $relative_uri (optional)
    - \%args        (optional)

Makes an HTTP request (where C<$method> is GET, PUT, POST, etc) and returns a
L<Net::CouchDB::Response> object on sucess.  If there was any kind of failure,
an exception is thrown.

The optional parameter C<$relative_uri> specifies a URI relative to the value
returned by C<< $self->uri >> (which users of this module must implement).  If
the parameter is not given, the value of C<< $self->uri >> is used directly.

The following optional named arguments are also accepted through the C<\%args>
hashref.

=head3 HTTP status codes

HTTP status codes as arguments specify what should happen if the HTTP request
returns that particular status code.  The value should be a string.  If the
string is "ok", the response is considered a success.  Otherwise, the response
is considered a failure and the value will be used as part of the exception
message.  If the response's status code is not listed in the arguments, a
general exception is thrown explaining that the status code was unknown.  For
example, let's use this request invocation:

    my $res = $self->request('GET', {
        200 => 'ok',
        404 => 'The document is no longer available',
    });

If the response has a 200 code, everything works and C<$res> will be a
L<Net::CouchDB::Response> object.  If the response has a 404 code, an
exception matching "The document is no longer available" is thrown.  For any
other status code, an exception is thrown.

Of course, multiple status codes may be listed as 'ok'.

=head3 content

Specifies the content of the HTTP request.  If this argument is a Perl
reference, it will be serialized to JSON.  Otherwise, the content is used
directly.

=head3 headers

Specifies a hashref of HTTP headers that should be added to the request.  The
keys should be the header names.  They values should be the header values.

=head3 description

A description of what this request is trying to accomplish.  If an exception
is thrown, this description is used as part of the exception message.

=head3 params

A hashref whose keys and values are added to the URI when making the request.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 DEBUG

If the DEBUG environment variable is set to a true value, the HTTP requests
and responses will be shown on STDERR.

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
