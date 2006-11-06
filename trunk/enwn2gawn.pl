#!/usr/bin/perl

use strict;
use warnings;

my %wnga;  # see makewn2ga.pl; hash of arrays, keys are sense_keys,
           # values are array refs with ga words in the array
open(WNGA, "<", "wn2ga.txt") or die "Could not open wn2ga.txt: $!\n";
while (<WNGA>) {
	chomp;
	(my $sk, my $focail) = /^([^|]+)\|(.+)$/;
	$wnga{$sk} = [ split /,/,$focail ];
}
close WNGA;

my %gafreq;  # see makewn2ga.pl; hash of arrays, keys are sense_keys,
           # values are array refs with ga words in the array
open(ROGET, "<", "roget.txt") or die "Could not open roget.txt: $!\n";
while (<ROGET>) {
	chomp;
	(my $cnt, my $word) = /^([0-9]+) (.+)$/;
	$gafreq{$word} = $cnt;
}
close ROGET;

my %adjlookup;

open(SENSEINDEX, "<", "index.sense") or die "Could not open index.sense: $!\n";
while (<SENSEINDEX>) {
	chomp;
	(my $sense_key, my $offset, my $wnsensenumber, my $count) = /^([^ ]+) ([0-9]{8}) ([0-9]+) ([0-9]+)$/;
	(my $lemma, my $ss_type, my $lex_filenum, my $lex_id) = $sense_key =~ /^([^%]+)%([1-5]):([0-9][0-9]):([0-9][0-9])/;
	if ($ss_type == 5) {
		$adjlookup{"$lemma|$offset"} = $sense_key;
	}
}
close SENSEINDEX;

my %pos_codes = ('n' => '1',   # used for generating sense key correctly
				'v' => '2',
				'a' => '3',
				'r' => '4',
				's' => '5',
				);

my %irish_words;

sub my_sort {
	if ($irish_words{$a} == $irish_words{$b}) {
		my $aval=0;
		my $bval=0;
		$aval = $gafreq{$a} if (exists($gafreq{$a}));
		$bval = $gafreq{$b} if (exists($gafreq{$b}));
		if ($aval == $bval) {
			return $a cmp $b;
		} 
		else {
			return $bval <=> $aval;
		}
	}
	else {
		return $irish_words{$b} <=> $irish_words{$a};
	}
}

sub process_data_file
{
	(my $file) = @_;
	open(DATAFILE, "<", $file) or die "Could not open $file: $!\n";
	my $outputfile = $file;
	$outputfile =~ s/^/ga-/;
	open(OUTPUTFILE, ">", $outputfile) or die "Could not open $outputfile: $!\n";
	while (<DATAFILE>) {
		chomp;
		unless (/^  /) {
			(my $synset_offset, my $lex_filenum, my $ss_type, my $w_cnt, my $rest) = /^([0-9]{8}) ([0-9][0-9]) ([nvasr]) ([0-9a-f][0-9a-f]) (.+)$/;
			my $decimal_words = hex($w_cnt);
			my $pos = $ss_type;
			$pos = 'a' if ($pos eq 's');
			$pos = 'adv' if ($pos eq 'r');
			%irish_words = ();
			for (my $i=0; $i < $decimal_words; $i++) {
				$rest =~ s/^([^ ]+) ([0-9a-z]) //;
				my $lemma=$1;
				my $lex_id_hex=$2;
				my $sense_key;
				$lemma =~ s/\([a-z]+\)$//; # s or a only:  "syntactic marker"
				if ($ss_type eq 's') {
					$sense_key = $adjlookup{"\L$lemma"."|$synset_offset"};
				}
				else {
					# for non-adjs, rebuild the sense_key just from data in data.*
					my $ss_num_type = $pos_codes{$ss_type};
					my $lex_id=sprintf("%02d", hex($lex_id_hex));
					$sense_key = "\L$lemma".'%'.$ss_num_type.':'.$lex_filenum.':'.$lex_id.'::';
					# should be same as adjlookup as in 's' case
				}
				foreach my $ir (@{$wnga{$sense_key}}) {
					$ir =~ s/$/\/$pos/ unless ($ir =~ / /);
					$irish_words{$ir}++;  # keys should match roget.txt (gafreq)
				}
			}
			my $icount = scalar keys %irish_words;
			if ($icount > 0) {
				print OUTPUTFILE "$synset_offset $ss_type $icount ";
				foreach my $i (sort my_sort keys %irish_words) {
					$i =~ s/ /_/g;
					$i =~ s/\/.*//;
					print OUTPUTFILE "$i ";
				}
				print OUTPUTFILE "$rest\n";
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
		}
	}
	close DATAFILE;
	close OUTPUTFILE;
}

process_data_file('data.adj');
process_data_file('data.adv');
process_data_file('data.noun');
process_data_file('data.verb');
