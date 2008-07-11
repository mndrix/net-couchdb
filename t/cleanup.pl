use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use Test::CouchDB;
use Net::CouchDB;

my $couch = Net::CouchDB->new( $ENV{NET_COUCHDB_URI} );
for my $db ( $couch->all_dbs ) {
    next if $db->name !~ m/^net-couchdb-\d+-\d+$/;
    warn "Deleting " . $db->name . "\n";
    $db->delete;
}
