use strict;
use Test::More;
use File::Spec;

use App::Riera;

# methods
can_ok 'App::Riera', qw/new to_yaml from_yaml/;

# no config
eval { App::Riera->new };
like $@, qr/Hiera config must be provided/, 'Constructor fails w/o Hiera config path';

# nonexistent config
my $dummy_yaml = File::Spec->catfile('t', 's', 'hiera', 'dummy.yaml');
eval { App::Riera->new({ config => $dummy_yaml }) };
like $@, qr/File '$dummy_yaml' does not exists/, 'Constructor fails w/ dummy config path';

# config without redis settings
my $hiera2_yaml = File::Spec->catfile('t', 's', 'hiera2.yaml');
eval { App::Riera->new({ config => $hiera2_yaml }) };
like $@, qr/Redis settings not found/, 'Constructor fails w/o redis settings in Hiera config';

# normal config (just illegal redis server name and port)
my $hiera1_yaml = File::Spec->catfile('t', 's', 'hiera1.yaml');
eval { App::Riera->new({ config => $hiera1_yaml }) };
like $@, qr/Could not connect to Redis server/, 'Constructor fails w/ redis settings';

done_testing();
