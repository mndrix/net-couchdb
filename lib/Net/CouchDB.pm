package Net::CouchDB;

use warnings;
use strict;
use HTTP::Request;
use JSON::Any;
use LWP::UserAgent;
use Net::CouchDB::DB;

our $VERSION = '0.01';

sub new {
    my ($class, $uri) = @_;
    my $ua   = LWP::UserAgent->new;
    my $res = $ua->get($uri);
    die "Unable to retrieve $uri\n" if not $res->is_success;
    my $json = JSON::Any->new;
    my $about = $json->decode( $res->content );
    return bless {
        base_uri => $uri,
        about    => $about,
        json     => $json,
        ua       => $ua,
    }, $class;
}

sub version {
    my ($self) = @_;
    return $self->{about}{version};
}

sub create_db {
    my ($self, $name) = @_;
    return Net::CouchDB::DB->new({
        couch  => $self,
        name   => $name,
        create => 1,
    });
}

sub all_dbs {
    my ($self) = @_;
    my $res = $self->call( 'GET', '_all_dbs' );
    die "Unable to retrieve a list of all databases from the CouchDB "
      . "instance located at " . $self->uri . ".  Got HTTP code "
      . $res->code . ".\n" if $res->code != 200;

    my $db_list = $self->json->decode( $res->content );

    # inflate the names into DB objects
    my @dbs = map {
        Net::CouchDB::DB->new({ couch => $self, name => $_ })
    } @$db_list;

    return wantarray ? @dbs : \@dbs;
}

# private-ish methods

sub call {
    my ( $self, $method, $partial_uri ) = @_;
    my $req = HTTP::Request->new( $method, $self->uri . '/' . $partial_uri );
    return $self->ua->request($req);
}

sub json {
    my ($self) = @_;
    return $self->{json};
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
 
 
=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.


=head1 CONFIGURATION AND ENVIRONMENT

Net::CouchDB requires no configuration files or environment variables.

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.


=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to internal limitations of Perl
(for example, many modules that use source code filters are mutually
incompatible).


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
