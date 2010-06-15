#!/usr/bin/perl
use strict;
use warnings;
use Switch;
use IO::Socket::INET;
use constant SERVER_PORT => 6666;
use constant CLIENT_ID => 8989;

# Create a new socket

my $MySocket;
my $def_msg="Enter message to send to server : ";
my $server_reply;

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
		if(send($MySocket,$msg,0))
		{
			return "sent $_[0]","\n";
		}
		else
		{
			return "error in sending message";
		}
}
sub handle_queue{
	if(@_ != 0){
	my $input = join(" ",@_);
	print $input;
	return send_to_server($input);
	}
}
sub load_file_and_queue{
	my $file = shift(@_);
	my $data = " ";
	open LOAD_FILE, "<$file" or die $!;
	while (<LOAD_FILE>) 
	{
		my $url= $_;
		chomp($url);
		$data = $data." ".$url;
	}
#	print ("queue".$data);
	return send_to_server("queue".$data);
}

sub start_client{
	print "client started ";
	$MySocket = connect_server();
	print "connected to server\n";
	my $lpid;
	die "can't fork: $!" unless defined($lpid = fork());
	
	if ($lpid == 0) 
		{
		while ($server_reply = <$MySocket>)
			{
			if($server_reply ne '')
				{
				print "reply from server is $server_reply\n";
				}
			}	
		}
	else{
		while (1)
			{	print "\n Send message to server : ";
				my $input = <STDIN>;
				my @tokens = split(/ /,$input);
				switch ($tokens[0]){
					shift(@tokens);
					case "queue_url" {
									print handle_queue(@tokens);  
					}
					case "queue_file"{
									print load_file_and_queue(@tokens);
					}
					case "config_file"{
									print "";
					}
					case "retrieve_data"{
									print "";
					}
				}
			}
		}		
}
start_client();
