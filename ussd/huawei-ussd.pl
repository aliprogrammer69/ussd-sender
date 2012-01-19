#!/usr/bin/perl

use Getopt::Std;
use FindBin;
use lib "$FindBin::Bin/lib";
use Device::Gsm::Pdu;
# defaults
$opt_r = "/dev/ttyUSB2";
$opt_s = "/dev/ttyUSB2";

my $USAGE = <<__EOU;

Usage: $0 [-r input_port] [-s output_port] [-n] [-h] [-v] [-w] ussd_msg

Description:
  Send and receive 7-bit PDU-encoded USSD messages.
  Written and tested for Huawei E173 GSM/UMTS USB modem.

Options:
  -r port   Port to receive data from. Default: $opt_r
  -s port   Port to send AT commands to. Default: $opt_s
  -n        Do not send any data to port. Useful with -v.
  -h        Print this help.
  -v        Be verbose.
  -w        reply workaround (try it if script can not decode reply)
__EOU

sub HELP_MESSAGE {print "$USAGE\n"; exit;}
sub VERSION_MESSAGE {};
getopts ('r:s:hnvw');
HELP_MESSAGE() and exit if (! $ARGV[0]) or defined($opt_h);

print "USSD MSG: $ARGV[0]\n" if $opt_v;
my $ussd_req = Device::Gsm::Pdu::encode_text7($ARGV[0]);
$ussd_req =~ s/^..//;
print "PDU ENCODED: $ussd_req\n" if $opt_v;

my $ussd_reply;
if (! $opt_n) {
    open (SENDPORT, '+<', $opt_s) or print STDOUT "Can't open '$opt_s': $!\n";
    print SENDPORT 'AT+CUSD=1,',$ussd_req,",15\r\n";
    close SENDPORT;
    open (RCVPORT, $opt_r) or print STDOUT "Can't open '$opt_r': $!\n";
    print "Waiting for USSD reply...\n" if $opt_v;
    while (<RCVPORT>) {
        chomp;
        die "USSD ERROR\n" if $_ eq "+CUSD: 2";
        if (/^\+CUSD: 0,\"([A-F0-9]+)\"/) {
            $ussd_reply = $1;
            print "PDU USSD REPLY: $ussd_reply\n" if $opt_v;
            last;
        }
        print "Got unknown USSD message: $_\n" if /^\+CUSD:/ and $opt_v;
    }
}

if ($ussd_reply) {
    $decoded_ussd_reply = $opt_w ? pack('H*', $ussd_reply) : Device::Gsm::Pdu::pdu_to_latin1($ussd_reply);
    print STDOUT "USSD REPLY: $decoded_ussd_reply\n";
}
else
{
    print "No USSD reply!\n";
}
