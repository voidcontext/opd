#!/usr/bin/env perl
# vim: expandtab ts=2 sw=2

use Mojolicious::Lite;

use JSON::PP;
use File::Slurp;
use File::Basename;

use FindBin;
use lib "$FindBin::Bin/../lib";

use OmxplayerClient;

my $json = read_file('config.json');
my $config = decode_json($json);

my $client = new OmxplayerClient;

my @files = ();
my @labels = ();

sub refreshDirs {
  @files = sort {basename(dirname($a)) . basename($a) cmp basename(dirname($b)) . basename($b)} qx{find $config->{root} -regextype posix-egrep -iregex '.*(mkv|avi|mp4)\$' | grep -vi sample};
  @labels = map {basename(dirname($_)).'/' . basename $_ } @files;

}

refreshDirs();

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
  my $c = shift;
  $c->stash(files => \@files, labels => \@labels);

  $c->render('index');
};

get '/play' => sub {
  my $c = shift;
  my $path = $c->param('path');

  $path =~ s/\ /\\ /g;
  $client->open($path);

  $c->redirect_to('/playing');
};

get '/playing' => sub {
  my $c = shift;
  $c->render;
};

get 'refresh' => sub {
  my $c = shift;

  refreshDirs();

  $c->redirect_to('/');
};

get '/pp' => sub {
  my $c = shift;
  
  $client->playPause();
  $c->redirect_to('/playing');
};

get '/sendkey' => sub {
  my $c = shift;
  
  $client->send("KEY " . $c->param("key"));
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
<a href="/refresh">Refresh</a>
<% for(my $i = 0; $i < scalar @{$files}; $i++) { %>
  <a href="/play?path=<%= $files->[$i] %>"><%= $labels->[$i] %></a>
<% } %>

@@ playing.html.ep
% layout 'default';
% title 'Welcome';
<p>
Hopefully playing
</p>
<a href="/">Home</a>
<a href="/pp">Play/Pause</a>
<a href="/sendkey?key=k">Next audio stream</a>
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
