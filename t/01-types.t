use strict;
use warnings qw\ all \;
use Test::More;

sub bashon {
    my $cmd = shift;
    qx{/usr/bin/env /bin/bash --noprofile --rcfile ../bashon.sh -c '$cmd'}
}

subtest 'null' => sub {
    plan tests => 1;
    
    pass('oui');
};

done_testing()
