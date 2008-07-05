package Net::CouchDB;

use warnings;
use strict;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use Net::CouchDB::DB;
use Net::CouchDB::Response;

our $VERSION = '0.01';
our $JSON;

sub new {
    my ($class, $uri) = @_;
    my $ua   = LWP::UserAgent->new;
    my $res = $ua->get($uri);
    die "Unable to connect to the CouchDB at $uri\n" if not $res->is_success;
    my $about = $class->json->decode( $res->content );
    return bless {
        base_uri => $uri,
        about    => $about,
        ua       => $ua,
    }, $class;
}

sub about {
    return shift->{about};
}

sub version {
    my ($self) = @_;
    return $self->about->{version};
}

sub create_db {
    my ($self, $name) = @_;
    return Net::CouchDB::DB->new({
        couch  => $self,
        name   => $name,
        create => 1,
    });
}

sub db {
    my ($self, $name) = @_;
    return Net::CouchDB::DB->new({
        couch  => $self,
        name   => $name,
    });
}

sub all_dbs {
    my ($self) = @_;
    my $res = $self->request( 'GET', '_all_dbs', {
        description => 'retrieve a list of all documents',
        200         => 'ok',
    });

    # inflate the names into DB objects
    my @dbs = map {
        Net::CouchDB::DB->new({ couch => $self, name => $_ })
    } @{ $res->content };

    return wantarray ? @dbs : \@dbs;
}

# private-ish methods

sub call {
    my ( $self, $method, $partial_uri, $content ) = @_;
    warn "call() is DEPRECATED\n";
    die "Invalid content given to call()"
      if defined($content) && ref($content) ne 'HASH';
    my $req = HTTP::Request->new( $method, $self->uri . '/' . $partial_uri );
    $req->content( $self->json->encode($content) ) if defined $content;
    return $self->ua->request($req);
}

sub request {
    my $self         = shift;
    my $method       = shift;
    my $relative_uri = !ref( $_[0] ) ? shift() : '';
    my $args         = shift || {};

    my $uri = URI->new_abs( $relative_uri, $self->uri );
    my $req = HTTP::Request->new( $method, $uri );
    $req->header( Accept => 'application/json' );

    # set the request body if specified
    if ( my $body = $args->{body} ) {
        $req->content( ref $body ? $self->json->encode($body) : $body );
    }

    return Net::CouchDB::Response->new( $self->ua->request($req) );
}

sub json {
    my ($self) = @_;
    our $JSON;
    return $JSON if $JSON;
    return $JSON = JSON->new;
}

sub ua {
    my ($self) = @_;
    return $self->{ua};
}

sub uri {
    my ($self) = @_;
    return $self->{base_uri};
}

1;

__END__

=head1 NAME

Net::CouchDB - <One line description of module's purpose>


=head1 VERSION

This documentation refers to Net::CouchDB version 0.01


=head1 SYNOPSIS

    use Net::CouchDB;
    # Brief but working code example(s) here showing the most common usage(s)

    # This section will be as far as many users bother reading
    # so make it as educational and exemplary as possible.
 
 
=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)


=head1 METHODS

=head2 new($uri)

Connects to the CouchDB server located at C<$uri>.  If there is no
server at C<$uri>, dies with the message "Unable to connect to the CouchDB
server at $uri."

=head2 about

Returns a hashref with metadata about this particular CouchDB server.

=head2 all_dbs

Returns a list or arrayref, depending on context, of L<Net::CouchDB::DB>
objects indicating all the database that are present on the server.

=head2 create_db($name)

Creates a new database named C<$name> on the server and returns a
L<Net::CouchDB::DB> object.  If a database named C<$name> already
exists, throws an exception saying "A database named '...' already exists".
Any other error while trying to create the database generates a generic
exception.

=head2 db($name)

Returns a L<Net::CouchDB::DB> object for the database named C<$name>.

=head2 uri

Returns the base URI of the CouchDB server.

=head2 version

Returns the version number of this server's CouchDB software.

=head2 INTERNAL METHODS

These methods are primarily intended for internal use.  They're documented
here for completeness.

=head2 call($method, $relative_uri [,$content] )

This method is B<deprecated>.  Use L</request> instead.

Executes an API call against the CouchDB server.  The C<$method> is an
HTTP verb and C<$relative_uri> is a URI relative to the server's base URI.
C<$content> is an optional hashref which is serialized into JSON and provided
as the body of the API call.

Returns an L<HTTP::Response> object.

=head2 json

A class method that returns the L<JSON> object used for parsing the server's
JSON responses.

=head2 ua

Returns the L<LWP::UserAgent> object that's used when interacting with
the CouchDB server.

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
