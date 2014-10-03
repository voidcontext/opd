package OmxplayerClient;
# vim: expandtab ts=2 sw=2

use warnings;
use strict;

use IO::Socket::UNIX;

sub new {
  my $class = shift;
  my $self = {
    SOCK_PATH => '/tmp/opd.sock',
    socket => undef,
  };

  bless $self, $class;

  $self->init();

  return $self;
}

sub init {
  my $self = shift;
  
  if(defined $self->{socket}) {
    close $self->{socket};
  }

  $self->{socket} = IO::Socket::UNIX->new(
    Type => SOCK_STREAM,
    Peer => $self->{SOCK_PATH},
  );
  $self->{socket}->autoflush(1);
}

sub send {
  my $self = shift;
  my $message = shift;

  # somehow we should detect the socket status
  # and we shouldn't reinit the socket on every send request
  $self->init(); # unless $self->{socket}->connected;
  print {$self->{socket}} $message . "\n";
}

sub open {
  my $self = shift;
  my $movie = shift;

  $self->send("OPEN " . $movie);
}

sub playPause {
  my $self = shift;

  $self->send("KEY p");
}

sub quit {
  my $self = shift;

  $self->send("KEY q");
}

1;
