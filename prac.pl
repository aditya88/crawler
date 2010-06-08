#!/usr/bin/perl
use strict;
use LWP::UserAgent;
use Data::Dumper;
use URI;
use Digest::MurmurHash;
use Date::Parse;
=comment

my $url = "http://perldoc.perl.org";
my $ua = LWP::UserAgent->new();
    #$ua->delay(1/60);
    $ua->agent ('crawler bot'); 
    $ua->from( 'mediawords@cyber.law.harvard.edu' );
    $ua->timeout( 20 );
    $ua->max_size( 1024 * 1024 );
    $ua->max_redirect( 15 );

    my $response = $ua->head($url);
    
    my $date = $response->header('last-modified');

my $time = str2time($date);

my @parts = gmtime(time()-$time);
printf ("%4d days,%4d hours,%4d mins,%4d secs.\n",@parts[7,2,1,0]);
    print Dumper($response);
    
my $time = Time::Piece->strptime($date, "%Y%m%d %H:%M");

# Here it is, parsed but still in GMT.
say $time->datetime;



print $response->filename;
print "url before canon ->".$url;
my $url1 = URI->new($url)->canonical;
print "\nafter canonical ==>".$url1;
print "\nfinal url is  --> ".$url1->scheme().
"://".
$url1->host( ).
":".$url1->port( ).
$url1->path( ).
"?".
$url1->query( ) ;
my $hash = '45243';
print 'SELECT * FROM downloads WHERE mm_hash_location=\''.$hash.'\' ORDER  by downloads_id DESC ;' ;
=cut

=comment

sub standardize_url
{
	my $url = $_[0];
	$url = URI->new($url)->canonical;
	my $url1 = $url->scheme()."://".$url->host().":".$url->port().$url->path()."?".$url->query() ;
	$url = URI->new($url1);
	return ($url);	
}

my $hello = 'http://www.perl.org';
print standardize_url($hello);

==cut