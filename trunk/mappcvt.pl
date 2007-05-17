#!/usr/bin/perl

use strict;
use warnings;

my $OLDVERSION="2.1";
my $MAPPINGVERSION="21-30";

my %sensekeysold;
my %sensekeysnew; # hash of lists; keys are offsets, list entries are sensekeys
my %mappingover; # hash of lists; keys are offsets, entries are poss new offsets

sub read_mapp_file {
	(my $fn, my $pos) = @_;

	open(MAPP, "<", $fn) or die "Could not open $fn: $!";
	while (<MAPP>) {
		chomp;
		(my $key, my $rest) = /^([0-9]+) (.+)$/;
		while ($rest =~ m/([0-9]+ [^ ]+) /g) {
			push @{$mappingover{"$pos:$key"}}, "$pos:$1";
			push @{$mappingover{"5:$key"}}, "5:$1" if ($pos==3);
		}
	}
	close MAPP;
}


open(INDEX, "<", "/usr/share/wordnet$OLDVERSION/index.sense") or die "Could not open index.sense for old: $!";

while (<INDEX>) {
	chomp;
	(my $sk, my $pos, my $offset) = /^([^%]+%(.)[^ ]+) ([0-9]+)/;
	$sensekeysold{$sk} = "$pos:$offset";
}
close INDEX;

open(INDEX2, "<", "/usr/share/wordnet/index.sense") or die "Could not open index.sense for new: $!";

while (<INDEX2>) {
	chomp;
	(my $sk, my $pos, my $offset) = /^([^%]+%(.)[^ ]+) ([0-9]+)/;
	push @{$sensekeysnew{"$pos:$offset"}}, $sk;
}
close INDEX2;

my $path="/home/kps/seal/mapps/mapping-$MAPPINGVERSION";
read_mapp_file("$path/wn$MAPPINGVERSION.adj", 3);
read_mapp_file("$path/wn$MAPPINGVERSION.adv", 4);
read_mapp_file("$path/wn$MAPPINGVERSION.noun", 1);
read_mapp_file("$path/wn$MAPPINGVERSION.verb", 2);

open(ENWNPO, "<", "en2wn.po") or die "Could not open PO file: $!";

while (<ENWNPO>) {
	chomp;
	if (/^msgstr/) {
		s/^msgstr "//;
		s/"$//;
		my $msgstr = $_;
		unless ($msgstr eq 'NULL' or $msgstr eq '' or $msgstr =~ /^Content-Type/) {
			my $oldoff = $sensekeysold{$msgstr};  # in form "$pos:$offset";
			if (exists($mappingover{$oldoff})) {
				(my $w) = /^([^%]+)%/;
				print "$msgstr -> ";
				foreach my $newoff (@{$mappingover{$oldoff}}) {
					# newoff looks like "1:00092663 0.118"
					(my $trueoff, my $prob) = $newoff =~ /^([^ ]+) ([^ ]+)/;
					foreach my $newsk (@{$sensekeysnew{$trueoff}}) {
						(my $thisw) = $newsk =~ /^([^%]+)%/;
						if ($w eq $thisw) {
							print "$newsk $prob ";
						} #possibly no matches => change to ""...
					}
				}
				print "\n";
			}
			else {
				print "$msgstr -> NOMAP\n";
				# probably maps to NULL in new version!!
			}
		}
	}
}
close ENWNPO;
exit 0;
