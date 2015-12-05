#!perl
use strict;
use warnings;
use utf8;

use File::Basename;

use Text::Amuse::Compile::FileName;
use Test::More tests => 30;

for my $fstype (qw/unix mswin32/) {
    fileparse_set_fstype($fstype);
    my %filenames =  ('my-filename:0,2,3,post' => {
                                              partial => [0,2,3, 'post'],
                                              file => 'my-filename.muse',
                                             },
                      'my-filename' => {
                                        file => 'my-filename.muse',
                                       },
                      '/path/to/filename.muse' => {
                                                   file => 'filename.muse',
                                                  },
                      '../path/to/file.muse' => {
                                                 file => 'file.muse',
                                                },
                      '../path/to/file.muse:pre,1,4,5,1001' => {
                                                       file => 'file.muse',
                                                       partial => ['pre', 1,4,5,1001],
                                                      });
    foreach my $file (sort keys %filenames) {
        my $obj = Text::Amuse::Compile::FileName->new($file);
        is $obj->suffix, '.muse', "suffix is ok";
        is_deeply({ $obj->text_amuse_constructor }, $filenames{$file},
                  "constructor ok for $file");
        ok ($obj->path, "Path is " . $obj->path);
    }
}


