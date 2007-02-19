#!/usr/bin/perl -w

use strict;
use Frontier::Daemon;
use Frontier::RPC2;
use Storable;
use Encode qw(encode decode from_to is_utf8);
#  works on windows with or without "use bytes"
#use bytes;

$ENV{PATH}="/bin:/usr/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };
binmode STDOUT, ":bytes";  # debug statements and log file
die "Usage: $0 [-l|-m|-w]" unless ($#ARGV == 0 and $ARGV[0] =~ /^-[mlw]/);

my $mac=0;
my $win=0;
my $linux=0;

sub log_date_string {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
	my $ans = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
	$ans .= " MSWin" if $win;
	$ans .= " MacOS" if $mac;
	$ans .= " Linux" if $linux;   # no other possibilities
	return $ans;
}

sub interrupt_nicely {
	(my $signal) = @_;
	my $datestr = log_date_string();
	open (LOGFILE, '>>/home/httpd/lsg.log') or die "Could not open log file: $!";
	print LOGFILE "$datestr ! Caught signal $signal, exiting...\n";
	close LOGFILE;
	exit(1);
}


sub die_handler {
	(my $msg) = @_;
	my $datestr = log_date_string();
	open (LOGFILE, '>>/home/httpd/lsg.log') or die "Could not open log file: $!";
	print LOGFILE "$datestr ! Fatal exception: $msg.\n";
	close LOGFILE;
	exit(1);
}

$SIG{'HUP'} = 'interrupt_nicely';
$SIG{'INT'} = 'interrupt_nicely';
$SIG{'QUIT'} = 'interrupt_nicely';
$SIG{'TRAP'} = 'interrupt_nicely';
$SIG{'ABRT'} = 'interrupt_nicely';
$SIG{'STOP'} = 'interrupt_nicely';
$SIG{'__DIE__'} = 'die_handler';

my $port;
if ($ARGV[0] =~ /^-m/) {
	$mac=1;
	$port=8082;
}
elsif ($ARGV[0] =~ /^-l/) {
	$linux=1;
	$port=8080;
}
elsif ($ARGV[0] =~ /^-w/) {
	$win=1;
	$port=8081;
}


my $dstr = log_date_string();
open (LOGFILE, '>>/home/httpd/lsg.log') or die "Could not open log file: $!";
print LOGFILE "$dstr ! Starting daemon...\n";
close LOGFILE;

my $coder = Frontier::RPC2->new;
my $debug = 0;

# reference to a hash of arrays
my $href;
eval {$href = retrieve('morcego.hash')};
die "Problem loading thesaurus hash!: $!" if ($@ or !$href);

my %unambwords;   # $unambwords{'bean'} = 'bean+b';
open(UNAMBWORDS, "<", "unambword.txt") or die "Could not open unambword.txt: $!";
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

# prepare for returning so that each platform will process it correctly
# linux is ok with the utf8
# windows needs it decoded back to perl strings (processed as 8-bit I think)
# mac needs as 8-bit too but in the weird mac encoding
sub platformify {
	(my $str) = @_;

	if ($win) {
		$str = decode("utf8", $str);
	}
	elsif ($mac) {
		$str = decode("utf8", $str);
		$str =~ s/\x{C1}/\x{E7}/g;
		$str =~ s/\x{C9}/\x{83}/g;
		$str =~ s/\x{CD}/\x{EA}/g;
		$str =~ s/\x{D3}/\x{EE}/g;
		$str =~ s/\x{DA}/\x{F2}/g;
		$str =~ s/\x{E1}/\x{87}/g;
		$str =~ s/\x{E9}/\x{8E}/g;
		$str =~ s/\x{ED}/\x{92}/g;
		$str =~ s/\x{F3}/\x{97}/g;
		$str =~ s/\x{FA}/\x{9C}/g;
	}
	# linux => leave as utf8
	return $str;
}

sub log_this_request {
	(my $ionchur) = @_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
	my $datestr = log_date_string();
	open (LOGFILE, '>>/home/httpd/lsg.log') or die "Could not open log file: $!";
	print LOGFILE "$datestr / $ionchur\n";
	close LOGFILE;
}

sub getSubGraph {
	(my $nodeName, my $depth) = @_;
	log_this_request($nodeName);
	# testing with is_utf8 shows that args from Frontier have utf8 flag on
	my $utfnn = encode("utf8", $nodeName);  
	my $utfhashid = node_id_to_hash($utfnn);
	print "called getSubGraph with node=$nodeName (utf=$utfnn, hashid=$utfhashid), depth=$depth...\n" if $debug;
	my %nbhd;
	recursive_helper($utfhashid, $depth, \%nbhd);  # $utfhashid too!
	my %answer;
	foreach my $subgraphvert (keys %nbhd) {
		my $utfnodeid = hash_to_node_id($subgraphvert);
		my $vertexnodeid = platformify($utfnodeid);
		print "setting up XML-RPC for hashid=$subgraphvert, nodeid=$utfnodeid...\n" if $debug;
		my @nbrsinsubgraph;
		for my $cand (@{$href->{$subgraphvert}}) {
			if (exists($nbhd{$cand})) {
				my $toadd = platformify(hash_to_node_id($cand));
				push @nbrsinsubgraph, $toadd;
			}
		}
		(my $word, my $num, my $igpos) = $subgraphvert =~ /^([^+]+)\+([0-9][0-9])\+([^+]+)$/;
		$word =~ s/_/ /g;
		$word = platformify($word);
		$answer{$vertexnodeid}->{'title'} = $word;
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

Frontier::Daemon->new(ReuseAddr => 1, LocalPort => $port, methods => $methods, )
     or die "Couldn't start HTTP server: $!";
