#!/usr/bin/perl

use warnings;
use strict;

use IO::Socket::UNIX;

my $SOCK_PATH = '/tmp/opd.sock';

my $socket = IO::Socket::UNIX->new(
  Type => SOCK_STREAM,
  Peer => $SOCK_PATH,
);

print $socket join(' ', @ARGV);


