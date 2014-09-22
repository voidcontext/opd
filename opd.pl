#!/usr/bin/perl

use warnings;
use strict;

use IO::Socket::UNIX;
use IO::Handle;

my $SOCK_PATH = "/tmp/opd.sock";
unlink $SOCK_PATH if -e $SOCK_PATH;

my $player;

$SIG{INT} = \&onend;

my $socket = IO::Socket::UNIX->new(
  Local => $SOCK_PATH,
  Type => SOCK_STREAM,
  Listen => 1,
);

while(1) {
  next unless my $connection = $socket->accept;

  $connection->autoflush(1);
  while(my $line = <$connection>) {
    chomp $line;
    print "Line received: '$line'\n";
    if($line =~ /^OPEN\ (.+)/) {
      open($player, "|omxplayer -o hdmi $1")  || die "couldn't start omxplayer";
    } else {
      print $player $line;
      $player->flush();
    }
  }
}

sub onend {
  if($player) {
    close $player;
  }

  exit 0;
}

