package Net::CouchDB::DesignDocument;
use warnings;
use strict;
use base qw( Net::CouchDB::Document );

use Net::CouchDB::View;

sub language {
    my ($self) = @_;
    my $lang = $self->{language};
    return 'javascript' if not defined $lang;
    return $lang;
}

sub name {
    my ($self) = @_;
    ( my $name = $self->id ) =~ s{^_design/}{};
    return $name;
}

sub add_view {
    my ($self, $name, $definition) = @_;
    eval { $self->view($name) } and die "A view named '$name' already exists\n";
    $self->{views}{$name} = $definition;
    $self->update;
    return $self->view($name);
}

sub view {
    my ($self, $view_name) = @_;
    my $name = $self->name;
    my $views = $self->{views} or die "Design document '$name' has no views\n";
    my $definition = $self->{views}{$view_name}
        or die "Design document '$name' has no view named '$view_name'\n";
    return Net::CouchDB::View->new({
        design     => $self,
        name       => $view_name,
        definition => $definition,
    });
}

sub views {
    my ($self) = @_;
    my $views = $self->{views} or return;
    my @objects;
    while ( my ($name, $definition) = each %$views ) {
        push @objects, Net::CouchDB::View->new({
            design     => $self,
            name       => $name,
            definition => $definition,
        });
    }

    return wantarray ? @objects : \@objects;
}

1;

__END__

=head1 NAME

Net::CouchDB::DesignDocument - a document containing views

=head1 SYNOPSIS

    use Net::CouchDB;
    # connect to the server and select a database
    my $design = $db->document('_design/example');
    print "Design uses the language " . $design->language . "\n";
    for my $view ( $design->views ) {
        print "A view named '" . $view->name . "'\n";
    }

=head1 DESCRIPTION

A L<Net::CouchDB::DesignDocument> object represents a single design document
within a CouchDB database.

=head1 METHODS

Remember that L<Net::CouchDB::DesignDocument> is a subclass of
L<Net::CouchDB::Document>, so any methods on that class are also relevant to
this class.

=head2 add_view($name, \%definition)

Adds a view named C<$name> to the design document where the hashref
C<$definition> provides the map and reduce components of the view.
If a view named C<$name> already exists, an exception is thrown.

Returns a L<Net::CouchDB::View> object.

=head2 language

Returns the name of the programming language in which the views of this design
document are implemented.

=head2 name

Returns the name of this design document.  This is the portion of the document
ID after "_design/".

=head2 view

Returns a single L<Net::CouchDB::View> object for the named view.  If no
such view exists, an exception is thrown.  To create a new view within
a design document, see L</add_view>.

=head2 views

Returns a list (or arrayref, depending on context) of L<Net::CouchDB::View>
objects representing all of the views defined within this design document.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
