#!/usr/bin/env perl
# vim: expandtab ts=2 sw=2

use Mojolicious::Lite;

use JSON::PP;
use File::Slurp;

use FindBin;
use lib "$FindBin::Bin/../lib";

use OmxplayerClient;

my $json = read_file('config.json');
my $config = decode_json($json);

my $client = new OmxplayerClient;

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

  $client->open($files[$id]);

  $c->redirect_to('/playing');
};

get '/playing' => sub {
  my $c = shift;
  $c->render;
};

get '/pp' => sub {
  my $c = shift;
  
  $client->playPause();
  $c->redirect_to('/playing');
};

get '/quit' => sub {
  my $c = shift;

  $client->quit();
  $c->redirect_to('/');
};


app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<a href="/playing">Now playing</a>
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
