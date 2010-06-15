package MServer;

use warnings;
use strict;
use Data::Dumper;
use base qw(Net::Server::PreFork);
use Switch;

sub new{
	my ( $class,$engine ,$port ) = @_;
	my $self = {};
    bless( $self, $class );
    $self->engine( $engine );
	return $self;
}

sub handle_queue{
	my ($self) = @_;
	my $client_id = shift(@_);
	my @urls = shift(@_);
	my $dbs = $self->engine->dbs;
	my $dbs_result = $dbs->query( "SELECT * from downloads where state =  'queued'" );
	my @queued_downloads = $dbs_result->hashes(); 
	print STDERR "queued_downloads array length = " . scalar( @queued_downloads ) . "\n";

=comment
	while(@urls != 0) {
		$self->engine->dbs->create(
                    'downloads_queue',
                    {
	                client_id     => $client_id,
	                url           => shift(@urls),
	                status        => 'new'
	                }
					);
	}
=cut
	
}

sub process_request {
	 my $self = shift;
	 print STDERR "inside process_request";
	 #print STDOUT "you are connected server";
	 while(my $msg = <STDIN>)
	 {
	 	my @tokens = split(/ /,$msg);
	 	my $client_id = shift(@tokens);
	 	switch(shift(@tokens)){
	 		case "queue"
	 		{
	 			$self->handle_queue($client_id,$msg);
	 		}
	 	}
	 	print STDERR $msg;
	 	print "recieved \n";
	 }
	 
=comment
        my $self = shift;
        while (<STDIN>) {
            s/\r?\n$//;
            print "You said '$_'\r\n", <STDIN>; # basic echo
            last if /quit/i;
        }
=cut

    }
    
sub post_accept_hook()
{
	print "configure_hook()";
}

sub engine
{
    if ( $_[ 1 ] )
    {
        $_[ 0 ]->{ engine } = $_[ 1 ];
    }

    return $_[ 0 ]->{ engine };
}


1;