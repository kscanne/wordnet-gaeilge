#!/usr/bin/perl -w

use strict;
use Frontier::Daemon;
use Frontier::RPC2;

$ENV{PATH}="/bin:/usr/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

my $coder = Frontier::RPC2->new;
my $debug = 1;

sub getSubGraph {
	(my $nodeName, my $depth) = @_;

	print "called getSubGraph with node=$nodeName, depth=$depth...\n" if $debug;
	return {
			'graph' => {
				'lár' => {
						'neighbours' => ['clé', 'deas'],
						'description' => 'nód sa lár!',
						'type' => 'round',
						'color' => '#FF0000',
						},
				'clé' => {
						'neighbours' => ['lár'],
						'description' => 'nód ar chlé!',
						'type' => 'round',
						'color' => '#FF0000',
						},
				'deas' => {
						'neighbours' => ['lár'],
						'description' => 'nód ar dheis!',
						'type' => 'round',
						'color' => '#FF0000',
						},
			},
	};
}

sub isNodePresent {
	(my $nodeName) = @_;
	print "called isNodePresent with node=$nodeName...\n" if $debug;
	if ($nodeName =~ m/^(left|center|right)$/) {
		return $coder->boolean(1);
	}
	else {
		return $coder->boolean(0);
	}
}

my $methods = {
			'getSubGraph' => \&getSubGraph,
			'isNodePresent' => \&isNodePresent,
};

Frontier::Daemon->new(LocalPort => 8080, methods => $methods)
     or die "Couldn't start HTTP server: $!";
