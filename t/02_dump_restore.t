use strict;
use Test::More;
use File::Spec;
use File::Temp;
use YAML ();

use App::Riera;

my $dummy_yaml = File::Spec->catfile('t', 's', 'hiera', 'dummy.yaml');
my $fh = File::Temp->new(TEMPLATE => 'hiera-XXXXXXX', SUFFIX => '.yaml');
my $db = File::Temp->new(TEMPLATE => 'dump-XXXXXXX', SUFFIX => '.yaml');

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

# Hiera database
my $hieradb = {
    # LIST
    'global:nameservers' => [
        '127.0.0.1',
        '8.8.8.8',
        '8.8.4.4',
    ],
    # HASH
    'global:default_group' => {
        'FreeBSD' => 'wheel',
        'Ubuntu'  => 'root',
        'default' => 'root',
    },
    # STRING
    'global:pkg_host' => 'packages.example.com',
};

# create temp config and database
YAML::DumpFile($fh->filename, $hieraconf);
YAML::DumpFile($db->filename, $hieradb);

my $t_hiera;

SKIP: {
    my $default_server = $hieraconf->{':redis'}->{':host'} . ':' . $hieraconf->{':redis'}->{':port'};

    eval { $t_hiera = App::Riera->new({ config => $fh->filename }) };
    plan skip_all => "Redis instance needs to be running on '$default_server' for this test" if $@;
    diag "Dump/restore tests with Redis instance on '$default_server'";

    isa_ok $t_hiera, 'App::Riera', 'Object';

    eval { $t_hiera->from_yaml($dummy_yaml) };
    like $@, qr/File '$dummy_yaml' does not exists/, 'Restore database from dummy YAML';

    ok $t_hiera->from_yaml($db->filename), 'Restore database from YAML';

    is_deeply YAML::Load($t_hiera->to_yaml), $hieradb, 'Dump database to YAML';
}

done_testing();
