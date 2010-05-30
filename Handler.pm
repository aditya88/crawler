package Handler;

# process the fetched response for the crawler:
# * store the download in the database,
# * store the response content in the fs,
# * parse the response content to generate more downloads (eg. story urls from a feed download)
# * parse the response content to add story text to the database

use strict;
use warnings;

# MODULES

use Data::Dumper;
use Date::Parse;
use DateTime;
use Encode;
use FindBin;
use IO::Compress::Gzip;
use URI::Split;
use Switch;
use Carp;
use Perl6::Say;
use List::Util qw (max maxstr);
use HTML::LinkExtractor;
use URI::URL;

use Downloads;

# CONSTANTS

# max number of pages the handler will download for a single story
use constant MAX_PAGES => 10;

# STATICS

my $_feed_media_ids     = {};
my $_added_xml_enc_path = 0;

# METHODS

sub new
{
    my ( $class, $engine ) = @_;

    my $self = {};
    bless( $self, $class );

    $self->engine( $engine );
    return $self;
}

# chop out the content if we don't allow the content type
sub _restrict_content_type
{
    my ( $self, $response ) = @_;

    if ( $response->content_type =~ m~text|html|xml|rss|atom~i )
    {
        return;
    }

    #if ($response->decoded_content =~ m~<html|<xml|<rss|<atom~i) {
    #    return;
    #}

    print "unsupported content type: " . $response->content_type . "\n";
    $response->content( '(unsupported content type)' );
}

# call get_page_urls from the pager module for the download's feed
sub _call_pager
{
    my ( $self, $download, $response ) = @_;

    if ( $download->{ sequence } > MAX_PAGES )
    {
        print "reached max pages (" . MAX_PAGES . ") for url " . $download->{ url } . "\n";
        return;
    }

    my $dbs = $self->engine->dbs;

    if ( $dbs->query( "SELECT * from downloads where parent = ? ", $download->{ downloads_id } )->hash )
    {
        print "story already paged for url " . $download->{ url } . "\n";
        return;
    }

    my $validate_url = sub { !$dbs->query( "select 1 from downloads where url = ?", $_[ 0 ] ) };
    
    my $content = $response->content;
    my $base = $response->base;
    my @links = ();

    my $LX = new HTML::LinkExtractor;
    $LX->parse(\$content);
    $LX->links();
    my @tags = @{$LX->links()};
    
    for (my $i=0;$i < @tags;$i++){ if (defined $tags[$i]->{href}) {push(@links,$tags[$i]->{href}); } }
    @links = map { $_ = url($_, $base)->abs; } @links;
    
    my %hash_links   = map { $_, 1 } @links;
    my @unique_links = keys %hash_links;
    
    my $j=0;
    foreach $j (@unique_links) 
    {
    	
		     	$dbs->create(
		            'downloads',
		            {
		                parent        => $download->{ downloads_id },
		                url           => $j,
		                host          => lc( ( URI::Split::uri_split( $j ) )[ 1 ] ),
		                type          => 'archival_only',
		                sequence      => $download->{ sequence } + 1,
		                state         => 'pending',
		                download_time => 'now()',
		                extracted     => 'f'
		            }
		        );
    	     
    	
    }
    $download ->{ extracted } = 't';
    $download->{ state } = 'success';
    print "made success";
    $dbs->update_by_id( "downloads", $download->{ downloads_id }, $download );
                   
=comment
    my $parent_link = $self->$dbs->find_by_id( 'downloads', $download->{ downloads_id } );
    if ( my $next_page_url =
        MediaWords::Crawler::Pager->get_next_page_url( $validate_url, $download->{ url }, $response->decoded_content ) )
    {

        print "next page: $next_page_url\nprev page: " . $download->{ url } . "\n";

        $dbs->create(
            'downloads',
            {
                parent        => $download->{ downloads_id },
                url           => $next_page_url,
                host          => lc( ( URI::Split::uri_split( $next_page_url ) )[ 1 ] ),
                type          => 'content',
                sequence      => $download->{ sequence } + 1,
                state         => 'pending',
                priority      => $download->{ priority } + 1,
                download_time => 'now()',
                extracted     => 'f'
            }
        );
    }
=cut

}

# call the content module to parse the text from the html and add pending downloads
# for any additional content
sub _process_content
{
    my ( $self, $download, $response ) = @_;

    $self->_call_pager( $download, $response );

    #MediaWords::Crawler::Parser->get_and_append_story_text
    #($self->engine->db, $download->feeds_id->parser_module,
    #$download->stories_id, $response->decoded_content);
}


sub handle_response
{
    my ( $self, $download, $response ) = @_;

    #say STDERR "fetcher " . $self->engine->fetcher_number . " handle response: " . $download->{url};

    my $dbs = $self->engine->dbs;

    if ( !$response->is_success )
    {
        $dbs->query(
            "update downloads set state = 'error', error_message = ? where downloads_id = ?",
            encode( 'utf-8', $response->status_line ),
            $download->{ downloads_id }
        );
        return;
    }

    # say STDERR "fetcher " . $self->engine->fetcher_number . " starting restrict content type";

    $self->_restrict_content_type( $response );

    # say STDERR "fetcher " . $self->engine->fetcher_number . " starting reset";

    # may need to reset download url to the last redirect url
    $download->{ url } = ( $response->request->url );

    $dbs->update_by_id( "downloads", $download->{ downloads_id }, $download );

    # say STDERR "switching on download type " . $download->{type};
    switch ( $download->{ type } )
    {
        case ('archival_only'||'content')
        {
            Downloads::store_content( $dbs, $download, \$response->decoded_content );
            $self->_process_content( $download, $response );
        }
        else
        {
            die "Unknown download type " . $download->{ type }, "\n";
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
