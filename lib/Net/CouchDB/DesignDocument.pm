package Net::CouchDB::DesignDocument;
use warnings;
use strict;
use base qw( Net::CouchDB::Document );

1;

__END__

=head1 NAME

Net::CouchDB::DesignDocument - a document containing views

=head1 SYNOPSIS

    use Net::CouchDB;
    # connect to the server and select a database
    my $design = $db->document('_design/example');
    print "Design document uses the language " . $design->language . "\n";
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

=head2 new

To obtain a L<Net::CouchDB::DesignDocument> object from an existing design
document, see L<Net::CouchDB::DB/document>.

TODO how should new design documents be created?

=head2 language

Returns the name of the programming language in which the views of this design
document are implemented.

=head2 uri

Returns a L<URI> object representing the URI of this design document.

=head2 views

Returns a list (or arrayref, depending on context) of L<Net::CouchDB::View>
objects representing all of the views defined within this design document.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.
