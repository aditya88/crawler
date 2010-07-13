#!/usr/bin/perl
use strict;
use warnings;
use Switch;
use IO::Socket::INET;
use threads;
use threads::shared;
use Perl6::Say;
use constant SERVER_PORT => 6666;
use constant CLIENT_ID => 8989;

# Create a new socket

my $MySocket;
my $def_msg="Enter message to send to server : ";
my $server_reply="";
my $inbox : shared ="";

sub connect_server{
my $MySocket=new IO::Socket::INET->new(	PeerPort=>SERVER_PORT,
										Proto=>'tcp',
										PeerAddr=>'localhost'
									   );
die "Could not create socket: $!\n" unless $MySocket;
return $MySocket;
}

sub send_to_server{
	my $msg = CLIENT_ID." ".$_[0]."\n";
	print STDERR $msg;
		if(send($MySocket,$msg,0))
		{
			return "sent $_[0] \n";
		}
		else
		{
			return "error in sending message";
		}
}

sub handle_queue{
	if(@_ != 0){
	my $request_id = shift(@_);
	my $input = join(" ",@_);
	print $input;
	return send_to_server($request_id." queue ".$input);
	}
}

sub load_file_and_queue{
	my $request_id = shift(@_);
	my $file = shift(@_);
	my $data = " ";
	if(open LOAD_FILE, "<$file")
	{
		while (<LOAD_FILE>) 
		{
			my $url= $_;
			chomp($url);
			$data = $data." ".$url;
		}
#		print ("queue".$data);
		return send_to_server($request_id." queue ".$data);
	}
	else 
	{
		return "Could not open file '$file '. $!" ;
	}
}

sub listen_server{
		while ($server_reply = <$MySocket>)
			{
			if($server_reply ne '')
				{
				say $server_reply;
				$inbox = $inbox."\n".$server_reply;
				}
			}	
}

sub start_client{
	print "client started ";
	$MySocket = connect_server();
	print "connected to server\n";
	my $thr = threads->new(\&listen_server);	
		while (1)
			{	print "\n Send message to server : ";
				my $input = <STDIN>;
				$input =~s/\n/ /g;
#				print STDERR $input;
				my @tokens = split(/\s+/,$input);
				switch ($tokens[0])
				{
					my $token = shift(@tokens);					
					case "new_request"{
									print send_to_server("request");
					}
					case "queue_url" {
									print handle_queue(@tokens);  
					}
					case "queue_file"{
									print load_file_and_queue(@tokens);
					}
					case (/'downloads_type'||'depth_of_search'||"refresh_rate"||"allowed_content"||"user_agent"||"commit_request"/)
					{
									my $request_id=shift(@tokens);
									print send_to_server($request_id." ".$token." ".join(" ",@tokens) );
					}
					case "check_inbox"{
									print "\n messages received from server are: ".$inbox;
									$inbox = "";
					}
					
=comment
					case "commit_request"{
									my $request_id=shift(@tokens);
									print 
					}
=cut

				}
			}
				
}

start_client();
