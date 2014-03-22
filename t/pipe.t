use strict;
use warnings;
use Test::More tests => 7;
use IO::Pipe;

my $pipe = IO::Pipe->new;

if (my $pid = fork()) { # Parent
    diag "Child is $pid\n";
    $pipe->reader();
    while (<$pipe>) {
        my ($level, $msg) = m/(\w+) (.+)/;
        like $level, qr/WARN|FATAL/, "Got $level";
        like $msg, qr/Hellow|Blabla/, "Got $msg";
    }
    ok($pipe->close, "Closed the pipe");
    ok(!$pipe->close, "Reclosing doesn't work");
    my $ripped = wait; # just to be sure
    my $exit_status = $?;
    is sprintf('%d', $? >> 8), 3, "Exit status caught correctly";
}
elsif (defined $pid) { # Child
    $pipe->writer();
    close(STDERR);
    close(STDOUT);
    $pipe->autoflush(1);
    print $pipe "WARN Hellow\n";
    print $pipe "FATAL Blabla\n";
    exit 3;
}

