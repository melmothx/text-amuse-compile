#!perl

use strict;
use warnings;

use Test::More tests => 21;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Spec;

use_ok('Text::Amuse::Compile::Webfonts', "use is ok");

my $dir = File::Spec->catdir(qw/t webfonts/);

my $webfonts = Text::Amuse::Compile::Webfonts->new(webfontsdir => $dir);

ok(!$webfonts, "Against non-existent directory, return undef");

# populate

mkdir $dir unless -d $dir;
my $spec = <<SPEC;
family Test
regular R.ttf
italic IX.ttf
bold B.ttf

# size
pippo 13
size 12
SPEC

write_file(File::Spec->catfile($dir, 'spec.txt'), $spec);
foreach my $ttf (qw/R I B BI/) {
    write_file(File::Spec->catfile($dir, "$ttf.ttf"), 1); # dummy
}

$webfonts = Text::Amuse::Compile::Webfonts->new(webfontsdir => $dir);

ok(!$webfonts, "Object not created (errors)");

$spec = <<SPEC;
family Test
regular R.ttf
italic I.ttf
bold B.ttf
bolditalic BI.ttf
size 12
SPEC
write_file(File::Spec->catfile($dir, 'spec.txt'), $spec);

$webfonts = Text::Amuse::Compile::Webfonts->new(webfontsdir => $dir);

ok($webfonts, "Object created (no errors)");

isnt $webfonts->srcdir, $dir, "srcdir is not the same as dir";

my %files = $webfonts->files;

foreach my $accessor (qw/family regular italic bold bolditalic size format mimetype/) {
    ok ($webfonts->$accessor, "$accessor is ok: " . $webfonts->$accessor);
}

foreach my $file (keys %files) {
    my $relfile = File::Spec->catfile($dir, $file);
    ok (-f $relfile, "$relfile exists indeed");
}

# test and cleanup
foreach my $file (values(%files)) {
    ok (-f $file, "$file exists") and unlink $file;
}



unlink File::Spec->catfile($dir, 'spec.txt');
rmdir $dir;

    
