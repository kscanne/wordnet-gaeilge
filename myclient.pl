#!/usr/bin/perl -w

# only used for testing server from the command line

use strict;
use utf8;   # for hard-coded strings below
use Frontier::Client;
use Encode qw(encode);

#binmode STDOUT, ":utf8";
binmode STDOUT, ":bytes";
my $server_url = 'http://borel.slu.edu:8080/RPC2';
my $server = Frontier::Client->new(url => $server_url,  debug => 1, );
# my $query = 'comhlíonadh+11';
# my $query = 'dragan+11';
my $query = 'zzz+11';
eval { $server->call('getSubGraph', $server->string(encode("utf8",$query)), $server->int(1)); };
eval { print $server->call('isNodePresent', $server->string('garbage+11'))->value; };
exit 0;
