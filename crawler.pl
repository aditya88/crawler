#!/usr/bin/perl

# start a daemon that crawls all feeds in the database.
# see MediaWords::Crawler::Engine.pm for details.

use strict;

BEGIN
{
    use FindBin;
    use lib "$FindBin::Bin";
}

use Engine;

sub main
{
    my $crawler = Engine->new();

    $crawler->processes(3);
    $crawler->throttle(1);
    $crawler->sleep_interval(10);

    $| = 1;

    $crawler->crawl();
}

main();