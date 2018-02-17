package Bashon;

use strict;
use warnings qw\ all \;

BEGIN {
    require Exporter;

    our @ISA = qw\ Exporter \;
    our @EXPORT = qw\ bashon \;
}

our sub bashon {
    my $cmd = shift;
    qx{/usr/bin/env /bin/bash --noprofile --norc -c '. bashon.sh;$cmd'}
}

1;
