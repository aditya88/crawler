package MServer;

use strict;
use warnings;
use base qw(Net::Server::PreFork); # any personality will do

sub new
{
    my ( $class, $engine ) = @_;

    my $self = {};
    bless( $self, $class );
    $self = bless( {
                   'server' => {
                                 'key1' => 'val1',
                                 # more key/vals
                               }
                 }, 'Net::Server' );
    
    return $self;
}

MServer->run(port => 6666,host =>'localhost');

    ### over-ridden subs below

sub process_request {
        my $self = shift;
        eval {
            local $SIG{'ALRM'} = sub { die "Timed Out!\n" };
            my $timeout = 30; # give the user 30 seconds to type some lines

            my $previous_alarm = alarm($timeout);
            while (<STDIN>) {
                s/\r?\n$//;
                print "You said '$_'\r\n";
                alarm($timeout);
            }
            alarm($previous_alarm);
        };

        if ($@ =~ /timed out/i) {
            print STDOUT "Timed Out.\r\n";
            return;
        }
    }
1;