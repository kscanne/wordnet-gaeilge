#!/usr/bin/perl

use strict;
use warnings;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# converts En-Ir dictionary in diolaim/c to a pot file that
# is used for mapping the English defs to WN sense_keys

open(ENIR, "<:utf8", "/home/kps/gaeilge/diolaim/c/en") or die "Could not open Eng-Ir dictionary: $!\n";

print "msgid \"\"\nmsgstr \"\"\n\"Content-Type: text/plain; charset=UTF-8\\n\"\n\n";
while (<ENIR>) {
	chomp;
	s/\[/{/g;
	s/\]/}/g;
	(my $word, my $disambpos, my $note, my $defs) = /^([^:]+)  ((?:[a-z]+)?(?: \([A-Z\/a-z'-]+\))?)\. (?:{([^}]+)})?: (.+)\.$/;
	if ($disambpos) {   # not "unknown" POS
		if ($disambpos =~ /^(?:a|n|v|adv)( |$)/) {
			print "#. $note\n" if ($note);
			print "#. ga=$defs\n";
			print "msgid \"$word  $disambpos\"\nmsgstr \"\"\n\n";
		}
	}
}
close ENIR;

exit 0;
