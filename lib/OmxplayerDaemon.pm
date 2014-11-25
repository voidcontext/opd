package OmxplayerDaemon;
# vim: expandtab ts=2 sw=2

use warnings;
use strict;

use IO::Socket::UNIX;
use IO::Handle;

use subs qw{quitPlayer debug};

sub debug {
  if($ENV{DEBUG}) {
    print "DEBUG: $_[0]\n";
  }
}

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

  $SIG{CHLD} = sub {
    $self->cleanupChild();
  };
}

sub listen {
  my $self = shift;
  my $socket = $self->{socket};

  while(1) {
    next unless my $connection = $socket->accept;

    $connection->autoflush(1);
    debug "read connection";
    while(my $line = <$connection>) {
      chomp $line;
      debug "process line";
      eval {
        $self->processLine($line);
      };
      if($@) {
        print "$@\n";
      }
    }
  }
}


sub processLine {
  my $self = shift;
  my $line = shift;

  if($line =~ /^OPEN\ (.+)/) {
    debug "open player";
    if($self->{player}) {
      $self->quitPlayer;
    }
    debug "open handler";
    open($self->{player}, "|omxplayer -o hdmi $1")  || die "couldn't start omxplayer";
    $self->{player}->autoflush(1);
    debug "handler opened";
  } elsif($line =~ /^KEY (p|q|k)/) {
    debug "key -> $1";
    if($1 eq 'q') {
      $self->quitPlayer;
    } elsif ($self->{player}) {
      print {$self->{player}} $1;
    }
  } elsif($line eq 'KEY right') {
    debug "key -> right";
    # got this with `cat -vet`
    print {$self->{player}} '^[[C';
  } else {
    #nop
  }
}

sub quitPlayer {
  my $self = shift;

  debug "quit player";
  if($self->{player}) {
    debug "send 'q' key";
    print {$self->{player}} 'q';
  }
}

sub cleanupChild {
  my $self = shift;

  debug "close handler";
  close $self->{player};
  $self->{player} = undef;
  debug "player handler released";
}

sub cleanup {
  my $self = shift;

  debug "cleanup";

  if($self->{player}) {
    close $self->{player};
  }

  close $self->{socket};
  unlink $self->{SOCK_PATH} if -e $self->{SOCK_PATH};

  exit 0;
}

1
