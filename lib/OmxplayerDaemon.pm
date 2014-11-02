package OmxplayerDaemon;
# vim: expandtab ts=2 sw=2

use warnings;
use strict;

use IO::Socket::UNIX;
use IO::Handle;

use subs qw{quitPlayer};

sub new {
  my $class = shift;
  my $self = {
    SOCK_PATH => "/tmp/opd.sock",
    player => undef,
    socket => undef,
  };

  bless $self, $class;

  $self->init();

  return $self;
}

sub init {
  my $self = shift;

  # create socket
  unlink $self->{SOCK_PATH} if -e $self->{SOCK_PATH};
  $self->{socket} = IO::Socket::UNIX->new(
    Local => $self->{SOCK_PATH},
    Type => SOCK_STREAM,
    Listen => 1,
  );
  $self->{socket}->autoflush(1);
}

sub listen {
  my $self = shift;
  my $socket = $self->{socket};

  while(1) {
    next unless my $connection = $socket->accept;

    $connection->autoflush(1);
    while(my $line = <$connection>) {
      chomp $line;
      eval {
        $self->processLine($line);
      }
    }
  }
}


sub processLine {
  my $self = shift;
  my $line = shift;

  if($line =~ /^OPEN\ (.+)/) {
    if($self->{player}) {
      print {$self->{player}} 'q';
      $self->quitPlayer;
    }
    open($self->{player}, "|omxplayer -o hdmi $1")  || die "couldn't start omxplayer";
    $self->{player}->autoflush(1);
  } elsif($line =~ /^KEY (p|q|k)/) {
    if($self->{player}) {
      print {$self->{player}} $1;
    }
    if($1 eq 'q') {
      $self->quitPlayer;
    }
  } elsif($line eq 'KEY right') {
    # got this with `cat -vet`
    print {$self->{player}} '^[[C';
  } else {
    #nop
  }
}

sub quitPlayer {
  my $self = shift;

  if($self->{player}) {
    close $self->{player};
    $self->{player} = undef;
  }
}

sub cleanup {
  my $self = shift;

  if($self->{player}) {
    close $self->{player};
  }

  close $self->{socket};
  unlink $self->{SOCK_PATH} if -e $self->{SOCK_PATH};

  exit 0;
}

1
