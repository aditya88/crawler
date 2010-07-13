package Fetcher;

use strict;
use DB;
use MediaWords;
use LWP::RobotUA;
use URI::Escape;
use Digest::MurmurHash qw(murmur_hash);
use Perl6::Say;
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
    my $url = URI::Escape::uri_unescape($download->{ url });
    my ($response,$ua);
    # make default
    print $download->{ _user_agent } ;
    if ($download->{ _user_agent } eq "")
    {
    	$ua = LWP::RobotUA->new('crawler bot (http://cyber.law.harvard.edu)','amaddula@cyber.law.harvard.edu');
    }
    else
    {
    	$ua = LWP::RobotUA->new($download -> { _user_agent },'amaddula@cyber.law.harvard.edu');
    }
    $ua->timeout( 20 );
    $ua->max_size( 1024 * 1024 );
    $ua->max_redirect( 15 );
    $ua->delay(1/60);

	if ($type eq "head"){
		$response = $ua->head( $url )
	}
	# else null or "content"
	else
	{
		$download->{ download_time } = 'now()';
	    $download->{ state }         = 'fetching';
	    $dbs->update_by_id( "downloads", $download->{ downloads_id }, $download );
	    $response = $ua->get( $url );
	}
    return $response;
	
}

sub fetch_download
{
    my ( $self, $download ) = @_;

    my $dbs = $self->engine->dbs;
    
    # FIXME - need to handle redirect manually, sticking them back into the queue as downloads
    # so that the host throttling works as it should
    # print "fetcher " . $self->engine->fetcher_number . " download: " . $download->{url} . "\n";
    
    my $download_head = do_fetch( $download, $dbs,"head");
    
    #content type checking in header
    if ( !($download_head->content_type =~ $download->{ _allowed_content }) )
    {
    	#content_type not supported
        return('cond5');
    }
    
    my $hash = murmur_hash( Handler::standardize_url($download_head->base) );
    my @out ;
    @out = $dbs -> query('SELECT * FROM downloads WHERE mm_hash_location=? ORDER  by downloads_id DESC',$hash )->hashes();
    if ( int( @out ) == 0 )
    {
    	# cond4  both  url and location not present in DB make new download
    	return ('cond4', do_fetch( $download, $dbs,"content") );
    }
    else {
    	# changing FEED_NOT_STALE_FOR to client specified value
	        if ( time() - ( $out[0] -> { download_time } ) > $download -> { _refresh_rate })
	        {
	        	if (str2time($download_head->header('last-modified')) < $out[0] -> { download_time } )
	        	{
	        		# download is stale  but content not modified
	        		# cond1 no download  required and path of the location is $out[0] -> { path }
	        		return ( 'cond1', $out[0], $download_head);
	        	}
	        	else
	        	{
	        		# cond2 make new copy since download is stale and header is modified
	        		return ( 'cond2', do_fetch( $download, $dbs,"content") );
	        	}
	        }
	        else 
	        {
	        	# cond3 no download  required and path of the location is $out[0] -> { path }
	        	return ( 'cond3', $out[0] );
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
