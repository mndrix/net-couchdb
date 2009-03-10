package Net::CouchDB::View;
use warnings;
use strict;

use Net::CouchDB::ViewResult;

sub new {
    my ($class, $args) = @_;
    return bless {
        design     => $args->{design},
        name       => $args->{name},
        map        => $args->{definition}{map},
        reduce     => $args->{definition}{reduce},
    }, $class;
}

sub name   { shift->{name} }
sub design { shift->{design} }

sub search {
    my $self = shift;
    my $args = shift || {};
    return Net::CouchDB::ViewResult->new({
        view => $self,
        %$args
    });
}

sub uri {
    my ($self) = @_;
    my $view_name = $self->name;
    my $design = $self->design;
    return URI->new_abs( "_view/".$self->name, $design->uri );
}

1;

__END__

=head1 NAME

Net::CouchDB::View - an object representing a view

=head1 SYNOPSIS

    for my $view ( $design->views ) {
        print "There's a view named " . $view->name . "\n";
    }

=head1 DESCRIPTION

=head1 METHODS

=head2 new

L<Net::CouchDB::View> objects should usually be obtained by calling
L<Net::CouchDB::DesignDocument/view>, L<Net::CouchDB::DesignDocument/views> or
L<Net::CouchDB::DesignDocument/add_view>.  This method is documented for
internal use.  Named arguments must include

    design     - a DesignDocument object
    name       - the name of this view
    definition - a hash reference definining 

=head2 design

Returns the L<Net::CouchDB::DesignDocument> that contains this view.

=head2 name

Returns the name of this view.

=head2 search

See L<Net::CouchDB::ViewResult/search>.

=head1 INTERNAL METHODS

=head2 uri

Returns a L<URI> object indicating the URI of the view.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
