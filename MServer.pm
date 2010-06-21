package MServer;

use warnings;
use strict;
use Data::Dumper;
use base qw(Net::Server::PreFork);
use Switch;
use DB;
use Perl6::Say;

sub new{
	my ( $class,$engine ,$port ) = @_;
	my $self = {};
    bless( $self, $class );
    $self->engine( $engine );
	return $self;
}

sub make_request{
	my ($self,$client_id) = @_;
	print STDERR "\n $client_id is the client id that requested new download";
	my $dbs = $self->engine->dbs;
	my $row = $dbs->create(
					            'requests',
					            {
					                client_id     => $client_id
					            }
					            );
	
	$dbs->commit();
	return $row->{ request_id };
=comment
	$dbs->query("INSERT INTO requests (client_id) VALUES (?)",$client_id);
	my $last_insert_id = $dbs->last_insert_id(undef,undef,'requests',undef);
	my $row = $dbs->find_by_id("requests",$last_insert_id)->hash;
	return $row->{ request_id };
=cut
}

sub handle_queue{
	my ($self,$client_id,$request_id,@urls) = @_;
	my $dbs = $self->engine->dbs;
#	print STDERR @urls;
#	shift(@urls);
	if($self->validate($client_id,$request_id))
	{
	while(scalar(@urls) != 0) {
		my $url = shift(@urls);
#		print scalar(@urls);
		$dbs->query("INSERT INTO downloads_queue (request_id,url,status) VALUES (?,?,'new')",$request_id,$url);
#   	print STDERR "inserted ",$url,"\n";
   		$dbs->commit();
	}	
	}
	else{
#TODO some error
	}
}

sub validate{
	
	my($self,$client_id,$request_id)=@_;
	my $dbs = $self->engine->dbs;
	my $result = $dbs->query("SELECT client_id FROM requests WHERE request_id=?",$request_id)->hash;
	if ($result->{ client_id } == $client_id){
		return 1;
	}
	else{
		return 0;
	}
}
sub make_settings{
	my($self,$client_id,$request_id,$case,@tokens) = @_;
	if($self->validate($client_id,$request_id)){
		
		my $dbs = $self->engine->dbs;
		my $request = $dbs->find_by_id( 'requests', $request_id );
        if ( !$request ) 
        { 
        	die( "error" ); 
        }
        $request->{ $case } = shift(@tokens);
#        print STDERR $request->{ $case }; 
        $dbs->update_by_id( "requests", $request->{ request_id }, $request );
        $dbs->commit();
	}
}

sub process_request {
	 my $self = shift;
	 #print STDOUT "you are connected server";
	 while(my $msg = <STDIN>)
	 {
	 	say STDERR $msg;
	 	my @tokens = split(/\s+/,$msg);
	 	my $client_id = shift(@tokens);
	 	my $switch=shift(@tokens);
	 	$switch=~s/\n//g;
	 	if($switch eq "request"){
	 		print STDERR "new request \n";
 			my $new_request_id = $self->make_request($client_id);
 			print STDERR "your request id is $new_request_id \n";
 			print STDOUT "you($client_id) made new request $new_request_id \n";	 		
	 	}
	 	else{
	 		my $request_id = $switch;
	 		my $case = shift(@tokens);
	 		switch($case){
		 		case "queue"
		 		{
		 			$self->handle_queue($client_id,$request_id,@tokens);
		 		}
		 		case (/"downloads_type"||"depth_of_search"||"refresh_rate"||"allowed_content"/)
		 		{
		 			print STDERR "switch done";
					$self->make_settings($client_id,$request_id,$case,@tokens);		 			
		 		}
	 		}	
	 	}
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