package Riera;

#
# ABSTRACT: Hiera-Redis interface
#
# by Anton Gerasimov me <at> zyxmasta <dot> com, 2012
#

use strict;
use Carp ();
use YAML ();
use Try::Tiny;
use Redis ();
use 5.010;

my $VERSION = '0.1.3';

sub new {
    my ($class) = shift;
    my $args = shift;

    my $self = {
        '-config' => $args->{config} || undef,
    };

    bless $self, $class;

    $self->init;
}

sub init {
    my ($self) = @_;
    Carp::croak __PACKAGE__ . ": Hiera config must be provided!" unless $self->{'-config'};

    my $hiera_config = $self->_load_yaml($self->{'-config'});

    if (ref($hiera_config) eq 'HASH' && ref($hiera_config->{':redis'}) eq 'HASH') {
        $self->{'-hname'} = $hiera_config->{':redis'}->{':host'} .
        ($hiera_config->{':redis'}->{':port'} ? ':'.$hiera_config->{':redis'}->{':port'} : '');
        $self->{'-db'} = defined $hiera_config->{':redis'}->{':db'} ?
                                 $hiera_config->{':redis'}->{':db'} : 0;

        $self->{'redi'} = Redis::->new(server => $self->{'-hname'}, debug => 0);
    }
    else {
        Carp::croak __PACKAGE__ . ": Redis settings not found!";
    }

    $self;
}

#
# Dump Hiera database to YAML
#
sub to_yaml {
    my ($self) = @_;

    my $vars = {};

    $self->{'redi'}->select($self->{'-db'});

    my @keys = $self->{'redi'}->keys('*');

    foreach my $key (sort @keys) {
        my $type = uc($self->{'redi'}->type($key));
        given ($type) {
            when ('HASH') {
                my %t_hash = @{ $self->{'redi'}->hgetall($key) };
                $vars->{$key} = \%t_hash;
            }
            when ('LIST') {
                $vars->{$key} = [ $self->{'redi'}->lrange($key, 0, -1) ];
            }
            when ('STRING') {
                $vars->{$key} = $self->{'redi'}->get($key);
            }
            default {
                # nothing to do
                Carp::carp __PACKAGE__ . ": Don't know how to handle '$type'";
            }
        }
    }

    YAML::Dump($vars);
}

#
# Restore Hiera database from YAML
#
sub from_yaml {
    my ($self, $dump) = @_;
    my $vars = $self->_load_yaml($dump);

    $self->{'redi'}->select($self->{'-db'});
    $self->{'redi'}->flushdb;

    foreach my $key (sort keys %$vars) {
        my $ref = ref($vars->{$key});
        given ($ref) {
            when ('HASH') {
                $self->{'redi'}->hmset($key, %{ $vars->{$key} });
            }
            when ('ARRAY') {
                $self->{'redi'}->rpush($key, @{ $vars->{$key} });
            }
            default {
                $self->{'redi'}->set($key, $vars->{$key});
            }
        }
    }

}

#
# Load YAML from file
#
sub _load_yaml {
    my ($self, $yaml) = @_;
    Carp::croak __PACKAGE__ . ": File '" . $yaml . "' does not exists!" unless -e $yaml;
    YAML::LoadFile($yaml);
}

1; # End of Riera
