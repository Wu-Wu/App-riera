use 5.010001;
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository => 'https://github.com/Wu-Wu/App-riera',
            bugtracker => 'https://github.com/Wu-Wu/App-riera/issues',
        },
    }
};

my %options = (
    NAME          => 'App::riera',
    AUTHOR        => 'Anton Gerasimov <chim@cpan.org>',
    VERSION_FROM  => 'lib/App/Riera.pm',
    ABSTRACT      => 'Dump and restore redis driven Hiera database',
    LICENSE       => 'perl',
    EXE_FILES     => [
        'scripts/riera'
    ],
    PREREQ_PM     => {
        'Redis'        => 0,
        'Getopt::Long' => 0,
        'IO::File'     => 0,
        'YAML'         => 0,
        'Carp'         => 0,

    },
    BUILD_REQUIRES => {
        'Test::More' => '0.98',
        'File::Spec' => 0,
        'File::Temp' => 0,
        'YAML'       => 0,
    },
    MIN_PERL_VERSION => '5.10.1',
    test => {
        'TESTS' => 't/*.t',
    },
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
);

WriteMakefile(%options);
