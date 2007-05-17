#!/usr/bin/perl


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
		unless ($_ eq 'NULL' or $_ eq '') {
			unless (exists ($sensekeys{$_})) {
				print "msgstr $_ not in index.sense...\n";
			}
		}
	}
}
close ENWNPO;
exit 0;
