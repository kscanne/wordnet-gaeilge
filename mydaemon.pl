#!/usr/bin/perl -w

use strict;
use Frontier::Daemon;
use Frontier::RPC2;
use Storable;
use Encode qw(encode decode);

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
	my $hub_p = ($utfnn =~ /\+00/);
	foreach my $nbr (@{$href->{$utfnn}}) {
		recursive_helper($nbr, $depth, $hashref) if ($hub_p or $depth>0 or $nbr =~ /\+00/);
	}
}

sub getSubGraph {
	(my $nodeName, my $depth) = @_;
	my $utfnn = encode("utf8", $nodeName);  # Frontier args are Perl strings?

	print "called getSubGraph with node=$nodeName (utf=$utfnn), depth=$depth...\n" if $debug;
	my %nbrs;
	recursive_helper($utfnn, $depth, \%nbrs);  # adds $utfnn too!
	my %answer;
	foreach my $nbr (keys %nbrs) {
		my @subgraphnbrs;
		for my $cand (@{$href->{$nbr}}) {
			push @subgraphnbrs, $cand if (exists($nbrs{$cand}));
		}
		my $perlnbr = decode("utf8", $nbr);
		my @neighbrs = map { decode("utf8", $_) } @subgraphnbrs;
		(my $word, my $num, my $igpos) = $perlnbr =~ /^([^+]+)\+([0-9]+)\+([^+]+)\+/;
		$word =~ s/_/ /g;
		$answer{$perlnbr}->{'title'} = $word;
		$answer{$perlnbr}->{'neighbours'} = \@neighbrs;
		$answer{$perlnbr}->{'description'} = $igpos;
		$answer{$perlnbr}->{'type'} = 'round';
		if ($num =~ /^00/) {
			$answer{$perlnbr}->{'color'} = '#00FF00';
		}
		else {
			$answer{$perlnbr}->{'color'} = '#FF0000';
		}
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

Frontier::Daemon->new(ReuseAddr => 1, LocalPort => 8080, methods => $methods)
     or die "Couldn't start HTTP server: $!";
