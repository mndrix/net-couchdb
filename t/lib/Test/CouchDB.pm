package Test::CouchDB;
use strict;
use warnings;
use Test::More;
use Net::CouchDB;

use base 'Exporter';
BEGIN { our @EXPORT = qw( setup_tests ) };

sub setup_tests {
    my $args = shift || {};
    if ( not $ENV{NET_COUCHDB_URI} ) {
        plan skip_all => 'Please set NET_COUCHDB_URI to a CouchDB instance URI';
        exit;
    }

    # create a database for testing
    return if not $args->{create_db};
    my $couch = Net::CouchDB->new( $ENV{NET_COUCHDB_URI} );
    my $db_name = sprintf "net-couchdb-$$-%d", int( rand 100_000 );
    $db_name = $ENV{NET_COUCHDB_DB} if $ENV{DEBUG} && $ENV{NET_COUCHDB_DB};
    push our @dbs, my $db = $couch->create_db($db_name);
    END { if ( !$ENV{DEBUG} ) { eval { $_->delete } for @dbs } }

    return $db;
}

1;

__END__

=head1 NAME

Test::CouchDB - module for Net::CouchDB tests

=head1 DESCRIPTION

This module contains some useful subroutines for testing L<Net::CouchDB>.

=head1 SUBROUTINES

=head2 setup_tests

This method should be called at the beginning of every test file.  It makes
sure that initial setup for the tests is done and skips tests if there is
no CouchDB instance available.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
