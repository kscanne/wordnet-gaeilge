#!/usr/bin/perl -w

use strict;
use bytes;
use Frontier::Daemon;
use Frontier::RPC2;
use Storable;
use Encode qw(encode);

$ENV{PATH}="/bin:/usr/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

my $coder = Frontier::RPC2->new;
my $debug = 1;

# reference to a hash of arrays
my $href;
eval {$href = retrieve('morcego.hash')};
die "Problem loading thesaurus hash!: $!\n" if ($@ or !$href);

sub recursive_helper {
	(my $utfnn, my $depth, my $hashref) = @_;
	print "called recursive_helper with utfnn=$utfnn, depth=$depth...\n" if $debug;

	return if (exists($hashref->{$utfnn}));
	print "haven't already visited this node...\n" if $debug;
	$hashref->{$utfnn}++;
	return if ($depth==0);
	$depth--;
	print "ERROR: $utfnn not found\n" if ($debug and !exists($href->{$utfnn}));
	foreach my $nbr (@{$href->{$utfnn}}) {
		recursive_helper($nbr, $depth, $hashref);
	}
}

sub getSubGraph {
	(my $nodeName, my $depth) = @_;
	my $utfnn = encode("utf8", $nodeName);  # Frontier args are Perl strings 

	print "called getSubGraph with node=$nodeName (utf=$utfnn), depth=$depth...\n" if $debug;
	my %nbrs;
	recursive_helper($utfnn, $depth, \%nbrs);  # adds $utfnn too!
	my %answer;
	foreach my $nbr (keys %nbrs) {
		(my $word, my $igpos) = $nbr =~ /^([^+]+)\+[0-9]+\+([^+]+)\+/;
		$word =~ s/_/ /g;
		$answer{$nbr}->{'title'} = $word;
		$answer{$nbr}->{'neighbours'} = $href->{$nbr};
		$answer{$nbr}->{'description'} = $igpos;
		$answer{$nbr}->{'type'} = 'round';
		$answer{$nbr}->{'color'} = '#FF0000';
	}
	return { 'graph' => \%answer };
}

sub isNodePresent {
	(my $nodeName) = @_;
	my $utfnn = encode("utf8", $nodeName);  # Frontier args are Perl strings 
	print "called isNodePresent with node=$utfnn...\n" if $debug;
	if (exists($href->{$utfnn})) {
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
