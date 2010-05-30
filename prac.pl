#!/usr/bin/perl
use strict;
use LWP::UserAgent;
use Data::Dumper;
use URI;

my $ua = LWP::UserAgent->new();
my $url = "http://picasaweb.google.com/";
    $ua->from( 'mediawords@cyber.law.harvard.edu' );
    $ua->agent( 'crawler bot (http://cyber.law.harvard.edu)' );

    $ua->timeout( 20 );
    $ua->max_size( 1024 * 1024 );
    $ua->max_redirect( 15 );

  #  my $response = $ua->get($url);
  #  print Dumper($response);

my $url1 = URI->new($url);

print "Scheme: ", $url1->scheme( ), "\n";
print "Userinfo: ", $url1->userinfo( ), "\n";
print "Hostname: ", $url1->host( ), "\n";
print "Port: ", $url1->port( ), "\n";
print "Path: ", $url1->path( ), "\n";
print "Query: ", $url1->query( ), "\n";
 