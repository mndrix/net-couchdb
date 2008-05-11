use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::CouchDB',
    VERSION_FROM => 'lib/Net/CouchDB.pm',
    LICENSE      => 'mit',
    PREREQ_PM    => {
        'LWP::UserAgent' => 0,
        'JSON'           => 2,
    },
);
