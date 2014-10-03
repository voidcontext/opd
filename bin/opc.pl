#!/usr/bin/perl
# vim: expandtab ts=2 sw=2

use warnings;
use strict;


use FindBin;
use lib "$FindBin::Bin/../lib";

use OmxplayerClient;

my $client = new OmxplayerClient();

$client->send(join ' ', @ARGV);
