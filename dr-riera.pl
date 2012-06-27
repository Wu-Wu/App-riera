#!/usr/bin/env perl

#
# ABSTRACT: Dump/restore the redis-driven Hiera database
#
# by Anton Gerasimov me <at> zyxmasta <dot> com, 2012
#
use strict;
use 5.010;
use Getopt::Long;
use IO::File;
use FindBin;
use lib "$FindBin::Bin/lib";
use Riera;

my $VERSION = '0.1.4';


my $args = {
    'config'   => "$FindBin::Bin/hiera.yaml",
    'filename' => "$FindBin::Bin/riera-dump.yaml",
    'dump'     => 1,
    'restore'  => 0,
};

GetOptions(
    'config|c=s'    => \$args->{'config'},
    'filename|f=s'  => \$args->{'filename'},
    'dump|d'        => \$args->{'dump'},
    'restore|r'     => \$args->{'restore'},
    'help|h|?'      => \$args->{'help'},
);

$args->{'dump'} = 0 if $args->{'restore'};

my $hr = Riera::->new({config => $args->{config}});

if ($args->{'dump'}) {
    say "Dump Riera database to " . $args->{'filename'} . '..';
    my $fh = new IO::File '> ' . $args->{'filename'};
    if (defined $fh) {
        print $fh $hr->to_yaml;
        $fh->close;
    }
    else {
        say "Cannot open " . $args->{'filename'} . ': ' . $!;
    }
}
else {
    say "Restore Riera database from " . $args->{'filename'} . '..';
    $hr->from_yaml($args->{'filename'});
}

1;
