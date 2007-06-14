#!/usr/bin/perl

# checks all mappings in en2wn.po to be sure they actually exist in 
# the current version of WN linked in this dir

use strict;
use warnings;

my %sensekeys;
open(INDEX, "<", "index.sense") or die "Could not open index.sense: $!";

while (<INDEX>) {
	chomp;
	s/ .+//;
	$sensekeys{$_}++;
}
close INDEX;

open(ENWNPO, "<", "en2wn.po") or die "Could not open PO file: $!";

while (<ENWNPO>) {
	chomp;
	if (/^msgstr/) {
		s/^msgstr "//;
		s/"$//;
		unless ($_ eq 'NULL' or $_ eq '' or m/^Content-Type/) {
			unless (exists ($sensekeys{$_})) {
				print "msgstr $_ not in index.sense...\n";
			}
		}
	}
}
close ENWNPO;
exit 0;
