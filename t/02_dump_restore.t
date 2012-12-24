use strict;
use Test::More;
use File::Spec;
use File::Temp;
use YAML ();

use App::Riera;

my $fh = File::Temp->new(TEMPLATE => 'hiera-XXXXXXX', SUFFIX => '.yaml');

# Hiera configuration
my $hieraconf = {
    ':backends' => [
        'redis'
    ],
    ':redis' => {
        ':host' => $ENV{REDIS_SERVER} || '127.0.0.1',
        ':port' => $ENV{REDIS_PORT}   || 6379,
        ':db'   => $ENV{REDIS_DBNUM}  || 3
    },
};

# create temp config
YAML::DumpFile($fh->filename, $hieraconf);

my $t_hiera;

SKIP: {
    my $default_server = $hieraconf->{':redis'}->{':host'} . ':' . $hieraconf->{':redis'}->{':port'};

    eval { $t_hiera = App::Riera->new({ config => $fh->filename }) };
    skip "Redis instance needs to be running on '$default_server' for this test", 1 if $@;
    diag "Dump/restore with Redis instance on '$default_server'";

    isa_ok $t_hiera, 'App::Riera', 'Object';
}

done_testing();
