#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 18;
use File::Spec::Functions qw/catfile/;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Temp;

my %options = (
               continuefootnotes => "\\counterwithout{footnote}{chapter}",
               centerchapter => "\\let\\raggedchapter\\centering",
               centersection => "\\let\\raggedsection\\centering",
              );

my %extra;

my $testfile = catfile(qw/t testfile options-2/);

foreach my $opt (sort keys %options) {
    $extra{$opt} = 1;
    my $c = Text::Amuse::Compile->new(extra => { %extra },
                                      tex => 1,
                                      pdf => $ENV{TEST_WITH_LATEX},
                                     );
    test_option($c, $testfile, $options{$opt});
}

%extra = ();

my $wd = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});
foreach my $opt (sort keys %options) {
    $extra{$opt} = 1;
    my $muse = read_file($testfile . '.muse');
    foreach my $k (keys %extra) {
        $muse = "#$k 1\n" . $muse;
    }
    my $target = catfile($wd, join('-', %extra));
    write_file($target . '.muse', $muse);
    my $c = Text::Amuse::Compile->new(tex => 1, pdf => $ENV{TEST_WITH_LATEX});
    test_option($c, $target, $options{$opt});
}

sub test_option {
    my ($c, $testfile, $exp) = @_;
    $c->compile($testfile . '.muse');
    my $tex = $testfile . '.tex';
    ok -f $tex;
    my $pdf = $testfile . '.pdf';
  SKIP: {
        skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
        ok(-f $pdf, "$pdf created");
    }
    my $body = read_file($tex);
    like $body, qr{\Q$exp\E};
   
}
