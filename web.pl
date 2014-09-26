#!/usr/bin/env perl
use Mojolicious::Lite;

use JSON::PP;
use File::Slurp;

use IO::Handle;
use IO::Socket::UNIX;

my $SOCK_PATH = '/tmp/opd.sock';

my $socket = IO::Socket::UNIX->new(
  Type => SOCK_STREAM,
  Peer => $SOCK_PATH,
);
$socket->autoflush();

my $json = read_file('config.json');
my $config = decode_json($json);

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
  my $c = shift;
  my @files = qx{find $config->{root} -regextype posix-egrep -iregex '.*(mkv|avi)\$'};

  $c->stash(files => \@files);

  $c->render('index');
};

get '/play' => sub {
  my $c = shift;
  my $id = $c->param('id');
  my @files = qx{find $config->{root} -regextype posix-egrep -iregex '.*(mkv|avi)\$'};

  print $socket "OPEN " . $files[$id] . "\n";
  $c->redirect_to('/playing');
};

get '/playing' => sub {
  my $c = shift;
  $c->render;
};

get '/pp' => sub {
  my $c = shift;
  
  print $socket "KEY p\n";
  $c->redirect_to('/playing');
};

get '/quit' => sub {
  my $c = shift;

  print $socket "KEY q\n";
  $c->redirect_to('/');
};


app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<% for(my $i = 0; $i < scalar @{$files}; $i++) { %>
  <a href="/play?id=<%= $i %>"><%= $files->[$i] %></a>
<% } %>

@@ playing.html.ep
% layout 'default';
% title 'Welcome';
<p>
Hopefully playing
</p>
<a href="/">Home</a>
<a href="/pp">Play/Pause</a>
<a href="/quit">Quit</a>

@@ pp.html.ep
% layout 'default';
% title 'Welcome';
Play/pause

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <style>
      a {display : block;}
    </style>
  </head>
  <body><%= content %></body>
</html>
