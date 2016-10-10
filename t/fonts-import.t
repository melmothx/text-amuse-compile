#!perl

use strict;
use warnings;
use Text::Amuse::Compile::Fonts::Import;
use Test::More;
use Data::Dumper;
use File::Spec;
use JSON::MaybeXS;
use Text::Amuse::Compile::Fonts;

my $output = File::Spec->catfile(qw/t fontspec.json/);
unlink $output if -f $output;
die "Cannot unlink $output" if -f $output;
my $importer = Text::Amuse::Compile::Fonts::Import->new(output => $output);

if (!$ENV{RELEASE_TESTING}) {
    plan skip_all => 'Importer test not required';
}
elsif ($importer->use_fclist && $importer->use_imagemagick) {
    plan tests => 5;
}
else {
    plan skip_all => 'Cannot test the font importer';
}

my $fclist = $importer->import_with_fclist;
my $im = $importer->import_with_imagemagick;

foreach my $exp ('Charis SIL', 'TeX Gyre Pagella') {
    is_deeply($fclist->{$exp}, $im->{$exp}, "Same $exp specifications from identify and fc-list");
}
my $imported = $importer->import;
ok($importer->import);
$importer->import_and_save;
ok (-f $output);
{
    open (my $fh, '<', $output);
    local $/ = undef;
    my $body = <$fh>;
    close $fh;
    my $data = decode_json($body);
    is_deeply $data, $imported;
}
my $from_file = Text::Amuse::Compile::Fonts->new($output);
my $from_data = Text::Amuse::Compile::Fonts->new($imported);
ok ($from_file);
ok ($from_data);
is_deeply($from_file->list, $from_data->list, "Loaded ok");
diag Dumper($from_file->list);
