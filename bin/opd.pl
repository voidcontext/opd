#!/usr/bin/perl
# vim: expandtab ts=2 sw=2

use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

use OmxplayerDaemon;

my $d = new OmxplayerDaemon;

$d->listen();

# register SIGINT handler
$SIG{INT} = sub {
  $d->cleanup();
};

