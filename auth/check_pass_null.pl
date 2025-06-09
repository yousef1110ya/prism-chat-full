#!/usr/bin/env perl
use strict;
use warnings;

use Dotenv;
use JWT::Decode;

my $domain = $ARGV[0] || "localhost";
# loading .env file 
Dotenv->load('.env');
my $jwt_secret = $ENV{'JWT_SECRET'} or die "JWT_SECRET not set in .env\n";

while (1) {
    my $buf = "";
    print STDERR "Waiting for packet...\n";

    my $nread = sysread STDIN, $buf, 2;
    unless ($nread == 2) {
        print STDERR "Port closed or error reading length\n";
        exit;
    }   

    my $len = unpack "n", $buf;
    $nread = sysread STDIN, $buf, $len;

    my ($op, $user, $host, $password) = split /:/, $buf;
    my $jid = "$user\@$domain";
    my $result;

    print STDERR "Received operation: $op\n";

    SWITCH: {
        $op eq 'auth' and do {
            my $decoded = eval {
                jwt_decode(
                token  => $password,
                key    => $jwt_secret,
                verify => 1,
            );
            };
            if ($@) {
                $result = 0;
            } else {
                $result = 1;
            }
           
            
            last SWITCH;
        };

        $op eq 'setpass' and do {
            $result = 1;
            last SWITCH;
        };

        $op eq 'isuser' and do {
            $result = 1;
            last SWITCH;
        };

        $op eq 'tryregister' and do {
            $result = 1;
            last SWITCH;
        };

        $op eq 'removeuser' and do {
            $result = 1;
            last SWITCH;
        };

        $op eq 'removeuser3' and do {
            $result = 1;
            last SWITCH;
        };

        # Default case
        $result = 0;
    }

    my $out = pack "nn", 2, $result ? 1 : 0;
    syswrite STDOUT, $out;
}
