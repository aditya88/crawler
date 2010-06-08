package Fetcher;

use strict;
use DB;
use MediaWords;
use LWP::RobotUA;
use Digest::MurmurHash qw(murmur_hash);

use constant FEED_NOT_STALE_FOR => 24*60*60;

sub new
{
    my ( $class, $engine ) = @_;

    my $self = {};
    bless( $self, $class );

    $self->engine( $engine );

    return $self;
}

sub do_fetch
{
    my ( $download, $dbs, $type ) = @_;
    my $response;
    
    my $ua = LWP::RobotUA->new('crawler bot (http://cyber.law.harvard.edu)',
    											'mediawords@cyber.law.harvard.edu');
    $ua->timeout( 20 );
    $ua->max_size( 1024 * 1024 );
    $ua->max_redirect( 15 );
    $ua->delay(1/60);

	if ($type eq "head"){
		$response = $ua->head( $download->{ url } )				 
	}
	# else null or "content"
	else
	{
		$download->{ download_time } = 'now()';
	    $download->{ state }         = 'fetching';
	    $dbs->update_by_id( "downloads", $download->{ downloads_id }, $download );
	    $response = $ua->get( $download->{ url } );
	}
    return $response;
}
sub standardize_url
{
	my ( $self, $url ) = @_;
	$url = URI->new($url)->canonical;
	$url = $url->scheme( )."://".$url->host( ).":".$url->port( ).$url->path( )."?".$url->query( ) ;
	$url = URI->new($url);
	return ($url) ;	
}

sub fetch_download
{
    my ( $self, $download ) = @_;

    my $dbs = $self->engine->dbs;
    
    # FIXME - need to handle redirect manually, sticking them back into the queue as downloads
    # so that the host throttling works as it should
    #print "fetcher " . $self->engine->fetcher_number . " download: " . $download->{url} . "\n";
    
=comment
    assume two cases
    case-1 : url not present in db
=cut

    my $download_head = do_fetch( $download, $dbs,"head");
    my $hash = murmur_hash( $download_head->base );
    my @out ;
    print "kool1";
    @out = $dbs -> query('SELECT * FROM downloads WHERE mm_hash_location=? ORDER  by downloads_id DESC',$hash )->hashes();
    print "kool2";
    if ( int( @out ) == 0 )
    {
    	# cond4  both  url and location not present in DB
    	return ('cond4', do_fetch( $download, $dbs,"content") );
    }
    else {
        if ( time() - ( $out[0] -> { download_time } ) > FEED_NOT_STALE_FOR)
        {
        	if (str2time($download_head->header('last-modified')) < $out[0] -> { download_time } )
        	{
        		# download is stale  but content not modified
        		# cond1 no download  required and path of the location is $out[0] -> { path }
        		return ( 'cond1', $out[0] -> { downloads_id } );
        	}
        	else
        	{
        		# cond2 make new copy since download is stale and header is modiied
        		return ( 'cond2', do_fetch( $download, $dbs,"content") );
        	}
        }
        else 
        {
        	# cond3 no download  required and path of the location is $out[0] -> { path }
        	return ( 'cond3', $out[0] -> { downloads_id } );
        }
    }
}

# calling engine
sub engine
{
    if ( $_[ 1 ] )
    {
        $_[ 0 ]->{ engine } = $_[ 1 ];
    }

    return $_[ 0 ]->{ engine };
}

1;
