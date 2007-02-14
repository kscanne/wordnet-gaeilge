#!/usr/bin/perl -w

use strict;
use Frontier::Daemon;
use Frontier::RPC2;
use Storable;
use Encode qw(encode decode from_to is_utf8);
#  works on windows with or without "use bytes"
#use bytes;

binmode STDOUT, ":bytes";  # only affects print, which is only debug statements
$ENV{PATH}="/bin:/usr/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

my $coder = Frontier::RPC2->new;
my $debug = 1;

# reference to a hash of arrays
my $href;
eval {$href = retrieve('morcego.hash')};
die "Problem loading thesaurus hash!: $!\n" if ($@ or !$href);

my %unambwords;   # $unambwords{'bean'} = 'bean+b';
open(UNAMBWORDS, "<", "unambword.txt") or die "Could not open ambword.txt: $!\n";
while (<UNAMBWORDS>) {
	chomp;
	/^([^+]+)/;
	$unambwords{$1}=$_;
}
close UNAMBWORDS;

# "focal+00" -> "focal+00+f1" or "geall+00+v1" unchanged
sub node_id_to_hash {
	(my $utfnode) = @_;
	(my $w, my $code) = $utfnode =~ /^([^+]+)\+([^+]+)/;
	unless ($utfnode =~ /\+..\+/) {   # unless it already has a POS...
		if (exists($unambwords{$w})) {
			$utfnode = $unambwords{$w};
			$utfnode =~ s/\+/+$code+/;
		}
		else {
			print "unambiguous-looking node ID $utfnode, but not in unambword.txt...\n" if $debug;
			$utfnode .= '+xx';
		}
	}
	return $utfnode;
}

# inverse of previous; strip POS if allowed
sub hash_to_node_id {
	(my $utfhash) = @_;
	my $unambkey = $utfhash;
	$unambkey =~ s/\+.+//;
	$utfhash =~ s/\+[^+]+$// if (exists($unambwords{$unambkey}));
	return $utfhash;
}

# just used to find the set of *vertices* within "depth" of "utfhashid",
# and adds their hashid's to hashref; worry about edges later
sub recursive_helper {
	(my $utfhashid, my $depth, my $hashref) = @_;
	print "called recursive_helper with utfhashid=$utfhashid, depth=$depth...\n" if $debug;

	return if (exists($hashref->{$utfhashid}));
	print "haven't already visited this node...\n" if $debug;
	$hashref->{$utfhashid}++;
	return if ($depth==0);
	$depth--;
	if (exists($href->{$utfhashid})) {
		my $hub_p = ($utfhashid =~ /\+00/);
		foreach my $nbr (@{$href->{$utfhashid}}) {
			recursive_helper($nbr, $depth, $hashref) if ($hub_p or $depth>0 or $nbr =~ /\+00/);
		}
	}
	else {
		print "ERROR: $utfhashid not found in morcego.hash\n" if $debug;
	}
}

sub getSubGraph {
	(my $nodeName, my $depth) = @_;
	# testing with is_utf8 shows that args from Frontier have utf8 flag on
	my $utfnn = encode("utf8", $nodeName);  
	my $utfhashid = node_id_to_hash($utfnn);
	print "called getSubGraph with node=$nodeName (utf=$utfnn, hashid=$utfhashid), depth=$depth...\n" if $debug;
	my %nbhd;
	recursive_helper($utfhashid, $depth, \%nbhd);  # $utfhashid too!
	my %answer;
	foreach my $subgraphvert (keys %nbhd) {
		my $utfnodeid = hash_to_node_id($subgraphvert);
		my $vertexnodeid = decode("utf8", $utfnodeid);
#		my $vertexnodeid = $utfnodeid;
		print "setting up XML-RPC for hashid=$subgraphvert, nodeid=$utfnodeid...\n" if $debug;
		my @nbrsinsubgraph;
		for my $cand (@{$href->{$subgraphvert}}) {
			push @nbrsinsubgraph, decode("utf8", hash_to_node_id($cand)) if (exists($nbhd{$cand}));
#			push @nbrsinsubgraph, hash_to_node_id($cand) if (exists($nbhd{$cand}));
		}
		(my $word, my $num, my $igpos) = $subgraphvert =~ /^([^+]+)\+([0-9][0-9])\+([^+]+)$/;
		$word =~ s/_/ /g;
		$answer{$vertexnodeid}->{'title'} = decode("utf8", $word);
#		$answer{$vertexnodeid}->{'title'} = $word;
		$answer{$vertexnodeid}->{'neighbours'} = \@nbrsinsubgraph;
		$answer{$vertexnodeid}->{'description'} = $igpos;
		$answer{$vertexnodeid}->{'type'} = 'round';
		if ($num =~ /^00/) {
			$answer{$vertexnodeid}->{'color'} = '#00FF00';
		}
		else {
			$answer{$vertexnodeid}->{'color'} = '#FF0000';
		}
	}
	return { 'graph' => \%answer };
}

sub isNodePresent {
	(my $nodeName) = @_;
	my $utfnn = encode("utf8", $nodeName);  
	print "called isNodePresent with node=$utfnn...\n" if $debug;
	if (exists($href->{node_id_to_hash($utfnn)})) {
		print "present.\n" if $debug;
		return $coder->boolean(1);
	}
	else {
		print "not present.\n" if $debug;
		return $coder->boolean(0);
	}
}

my $methods = {
			'getSubGraph' => \&getSubGraph,
			'isNodePresent' => \&isNodePresent,
};

Frontier::Daemon->new(ReuseAddr => 1, LocalPort => 8080, methods => $methods, )
     or die "Couldn't start HTTP server: $!";
