use strict;
use warnings qw\ all \;
use Bashon;
use Test::More;

is(bashon('printf %s salut'), 'salut', 'sourcing bashon.sh works');

my %exported = (
    BASHON_parse =><<EOH,
Usage: BASHON_parse <path.json> [<store-path>]
EOH
    BASHON_generate =><<EOH,
Usage: BASHON_generate <root>
EOH
);

for my $fun (keys %exported) {
    isnt(bashon("declare -f $fun"), '', "$fun is exported");
    is(bashon("$fun -h"), $exported{$fun}, "$fun has correct usage");
}

done_testing()
