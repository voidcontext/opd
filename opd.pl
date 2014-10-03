#!/usr/bin/perl
# vim: expandtab ts=2 sw=2

use warnings;
use strict;

use IO::Socket::UNIX;
use IO::Handle;

use subs qw{quitPlayer};

my $SOCK_PATH = "/tmp/opd.sock";
unlink $SOCK_PATH if -e $SOCK_PATH;

my $player;

$SIG{INT} = \&cleanup;

my $socket = IO::Socket::UNIX->new(
  Local => $SOCK_PATH,
  Type => SOCK_STREAM,
  Listen => 1,
);

$| = 1;
while(1) {
  next unless my $connection = $socket->accept;

  $connection->autoflush(1);
  while(my $line = <$connection>) {
    chomp $line;
    eval {
      processLine($line);
    }
  }
}

sub processLine {
  my $line = shift;
  if($line =~ /^OPEN\ (.+)/) {
    if($player) {
      print $player 'q';
      quitPlayer;
    }
    open($player, "|omxplayer -o hdmi $1")  || die "couldn't start omxplayer";
    $player->autoflush();
  } elsif($line =~ /^KEY (p|q)/) {
    if($player) {
      print $player $1;
    }
    if($1 eq 'q') {
      quitPlayer;
    }
  } elsif($line eq 'KEY right') {
    # got this with `cat -vet`
    print $player '^[[C';
  } else {
    #nop
  }
}

sub quitPlayer {
  if($player) {
    close $player;
    $player = undef;
  }
}

sub cleanup {

  if($player) {
    close $player;
  }

  close $socket;
  unlink $SOCK_PATH if -e $SOCK_PATH;

  exit 0;
}

