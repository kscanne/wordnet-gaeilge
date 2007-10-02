#!/usr/bin/perl

# used this to find UNAMBIGUOUS words in WN with the property that their 
# unique synset has *no* English word appearing as a def in IG

# then could look these up in Ba59 or focal.ie and add to IG

use strict;
use warnings;
use locale;

my %ht;

sub process_data_file
{
	(my $file, my $pass) = @_;
	my %ighash;
	open(DATAFILE, "<", $file) or die "Could not open $file: $!\n";
	if ($pass == 2) {
		my $outputfile = $file;
		$outputfile =~ s/^/unambig-/;
		open(OUTPUTFILE, ">", $outputfile) or die "Could not open $outputfile: $!\n";
		my $igfile = $file;
		$igfile =~ s/^data/ig/;
		open(IGFILE, "<", $igfile) or die "Could not open $igfile: $!\n";
		while (<IGFILE>) {
			chomp;
			$ighash{$_}++;
		}
		close IGFILE;
	}
	while (<DATAFILE>) {
		chomp;
		unless (/^  /) {
			(my $synset_offset, my $lex_filenum, my $ss_type, my $w_cnt, my $rest) = /^([0-9]{8}) ([0-9][0-9]) ([nvasr]) ([0-9a-f][0-9a-f]) (.+)$/;
			my $decimal_words = hex($w_cnt);
			my $pos = $ss_type;
			$pos = 'a' if ($pos eq 's');
			$pos = 'adv' if ($pos eq 'r');
			my $none_in_ig = 1;
			my $some_unambig = 0;
			my $synset_to_print;
			for (my $i=0; $i < $decimal_words; $i++) {
				$rest =~ s/^([^ ]+) ([0-9a-z]) //;
				my $lemma=$1;
				my $lex_id_hex=$2;
				my $sense_key;
				$lemma =~ s/\([a-z]+\)$//; # s or a only:  "syntactic marker"
				$ht{$lemma}++ if ($pass==1);
				if ($pass==2) {
					if (exists($ighash{$lemma})) {
						$none_in_ig = 0;
					}
					else {
						if ($ht{$lemma}==1) {
							$synset_to_print .= "$lemma=";
							$some_unambig = 1;
						}
					}
				}
			}
			$rest =~ s/^([0-9]{3}) //;
			my $p_cnt = $1;
			for (my $i=0; $i < $p_cnt; $i++) {
				$rest =~ s/^([^ ]+) ([0-9]{8}) ([nvasr]) ([0-9a-f]{4}) //;
				my $pointer_symbol=$1;
				my $offset=$2;
				my $pos=$3;
				my $sourcetarget=$4;
			}
			my $gloss = $rest;
			$gloss =~ s/^[^|]+\| //;   # kills frames for verbs too
			if ($pass==2 and $none_in_ig and $some_unambig) {
				print OUTPUTFILE "$synset_to_print||$gloss\n";
			}
		}
	}
	close DATAFILE;
	close OUTPUTFILE if ($pass==2);
#	if ($pass==1) {
#		for my $k (sort keys %ht) {
#			print "$k\n" if ($ht{$k}==1);
#		}
#	}
}

process_data_file('data.verb',1);
process_data_file('data.verb',2);
%ht = ();
process_data_file('data.adv',1);
process_data_file('data.adv',2);
%ht = ();
process_data_file('data.noun',1);
process_data_file('data.noun',2);
%ht = ();
process_data_file('data.adj',1);
process_data_file('data.adj',2);
