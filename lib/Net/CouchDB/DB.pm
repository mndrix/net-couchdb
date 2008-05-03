package Net::CouchDB::DB;

use strict;
use warnings;

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
            die "The CouchDB at $uri responded with an unknown code "
              . "$code when trying to create a new database named "
              . "'$name'.\n";
        }
    }

    # TODO verify that this database exists
    return $self;
}

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

sub call {
    my ( $self, $method, $partial_uri ) = @_;
    $partial_uri = $self->name . $partial_uri;
    return $self->couch->call( $method, $partial_uri );
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
