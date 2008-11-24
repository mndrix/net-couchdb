use strict;
use warnings;
use ExtUtils::MakeMaker;

# popule META.yml with some useful information
my %params;
if ( $ExtUtils::MakeMaker::VERSION ge '6.36' ) {
    $params{EXTRA_META} = <<'EOF';
resources:
    homepage: http://git.ndrix.com/?p=Net-CouchDB;a=summary
    license: http://www.opensource.org/licenses/mit-license.php
    Repository: git://ndrix.com/Net-CouchDB
    MailingList: mailto:net-couchdb@googlegroups.com
EOF
    }

WriteMakefile(
    NAME         => 'Net::CouchDB',
    VERSION_FROM => 'lib/Net/CouchDB.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE' => 'mit')
        : ()),
    PREREQ_PM    => {
        'LWP::UserAgent' => 0,
        'JSON'           => 2,
        'Storable'       => 0,  # core since 5.7.3
        'URI'            => 0,  # already required by LWP::UserAgent
    },
    %params,
);

