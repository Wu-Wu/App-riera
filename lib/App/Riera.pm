package App::Riera;

=pod

=head1 NAME

App::Riera - Dump and restore redis driven Hiera database

=head1 SYNOPSIS

    use App::Riera;
    my $hr = App::Riera->new({ config => '/usr/local/etc/puppet/hiera.yaml' });

    # dump database
    my $dump = $hr->to_yaml;
    ...

    # restore database
    $hr->from_yaml('/data/backups/riera-dump.yaml');
    ...

=cut

use 5.010001;
use strict;
use Carp ();
use YAML ();
use Redis ();

our $VERSION = '0.13';

=head1 METHODS

=over 4

=item B<new()>

Construct..

=cut

#
# Constructor
sub new {
    my ($class) = shift;
    my $args = shift;

    my $self = {
        '-config' => $args->{config} || undef,
    };

    bless $self, $class;

    Carp::croak __PACKAGE__ . ": Hiera config must be provided!" unless $self->{'-config'};

    my $hiera_config = $self->_load_yaml($self->{'-config'});

    if (ref($hiera_config) eq 'HASH' && ref($hiera_config->{':redis'}) eq 'HASH') {
        $self->{'-server'} = $hiera_config->{':redis'}->{':host'} . ':' .
                            ($hiera_config->{':redis'}->{':port'}
                                ? $hiera_config->{':redis'}->{':port'}
                                : 6379);
        $self->{'-db'} = defined $hiera_config->{':redis'}->{':db'}
                            ? $hiera_config->{':redis'}->{':db'}
                            : 0;

        eval {
            $self->{'redi'} = Redis->new(server => $self->{'-server'}, debug => 0);
        };
        if ($@ && $@ =~ /Could not connect to Redis server/) {
            Carp::croak __PACKAGE__ . ": Could not connect to Redis server!";
        }
    }
    else {
        Carp::croak __PACKAGE__ . ": Redis settings not found!";
    }

    $self;
}

=pod

=item B<to_yaml()>

Dump Hiera database to YAML..

=cut

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

=pod

=item B<from_yaml()>

Restore Hiera database from YAML..

=back

=cut

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

    1; # OK
}

#
# Load YAML from file
sub _load_yaml {
    my ($self, $yaml) = @_;
    Carp::croak __PACKAGE__ . ": File '" . $yaml . "' does not exists!" unless -e $yaml;
    YAML::LoadFile($yaml);
}

=pod

=head1 SEE ALSO

L<Redis>

L<YAML>

=head1 AUTHOR

Anton Gerasimov, E<lt>chim@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Anton Gerasimov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
