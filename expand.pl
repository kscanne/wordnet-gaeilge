#!/usr/bin/perl

use strict;
use warnings;

my %rev = (
	'@' => '~',
	'~' => '@',
	'@i' => '~i',
	'~i' => '@i',
	'#m' => '%m',
	'%m' => '#m',
	'#s' => '%s',
	'%s' => '#s',
	'#p' => '%p',
	'%p' => '#p',
	';c' => '-c',
	'-c' => ';c',
	';r' => '-r',
	'-r' => ';r',
	';u' => '-u',
	'-u' => ';u',
);

sub process_data_file
{
	(my $file) = @_;
	my $breisfile = $file;
	$breisfile =~ s/^data/breis/;
	my $outputfile = $file;
	$outputfile =~ s/\./plus./;
	my %toinsert;  # reversed relations to insert to actual PWN
	# Princeton WordNet data.* files are ASCII only
	my @breislines;
	open(BREISFILE, "<", $breisfile) or die "Could not open $breisfile: $!\n";
	while (<BREISFILE>) {
		next if (/^  /);
		push @breislines, $_;
		chomp;
		(my $synset_offset, my $lex_filenum, my $ss_type, my $w_cnt, my $rest) = /^([0-9]{8}) ([0-9][0-9]) ([nvasr]) ([0-9a-f][0-9a-f]) (.+)$/;
		my $decimal_words = hex($w_cnt);
		for (my $i=0; $i < $decimal_words; $i++) {
			$rest =~ s/^([^ ]+) ([0-9a-z]) //;
		}
		$rest =~ s/^([0-9]{3}) //;
		my $p_cnt = $1;
		for (my $i=0; $i < $p_cnt; $i++) {
			$rest =~ s/^([^ ]+) ([0-9]{8}) ([nvasr]) ([0-9a-f]{4}) //;
			my $pointer_symbol=$1;
			my $offset=$2;
			my $pos=$3;
			my $sourcetarget=$4;
			push @{$toinsert{"$offset $pos"}}, $rev{$pointer_symbol}." $synset_offset $ss_type $sourcetarget";
		}
		unless ($rest =~ m/^\| /) {
			print STDERR "Warning: line $. malformed in $breisfile: $rest\n";
		}
	}
	close BREISFILE;

	open(OUTPUTFILE, ">:utf8", $outputfile) or die "Could not open $outputfile: $!\n";
	# Princeton WordNet data.* files are ASCII only
	open(DATAFILE, "<", $file) or die "Could not open $file: $!\n";
	while (<DATAFILE>) {
		chomp;
		next if (/^  /);
		my $line = $_;
		(my $synset_offset, my $lex_filenum, my $ss_type, my $w_cnt, my $rest) = /^([0-9]{8}) ([0-9][0-9]) ([nvasr]) ([0-9a-f][0-9a-f]) (.+)$/;
		if (exists($toinsert{"$synset_offset $ss_type"})) {
			print OUTPUTFILE "$synset_offset $lex_filenum $ss_type $w_cnt ";
			my $decimal_words = hex($w_cnt);
			for (my $i=0; $i < $decimal_words; $i++) {
				$rest =~ s/^([^ ]+) ([0-9a-z]) //;
				print OUTPUTFILE "$1 $2 ";
			}
			$rest =~ s/^([0-9]{3}) //;
			my $p_cnt = $1;
			my $new_p_cnt = $p_cnt + scalar(@{$toinsert{"$synset_offset $ss_type"}});
			print OUTPUTFILE sprintf("%03d", $new_p_cnt).' ';
			for (my $i=0; $i < $p_cnt; $i++) {
				$rest =~ s/^([^ ]+) ([0-9]{8}) ([nvasr]) ([0-9a-f]{4}) //;
				my $pointer_symbol=$1;
				my $offset=$2;
				my $pos=$3;
				my $sourcetarget=$4;
				print OUTPUTFILE "$pointer_symbol $offset $pos $sourcetarget ";
			}
			for my $newp (@{$toinsert{"$synset_offset $ss_type"}}) {
				print OUTPUTFILE "$newp ";
			}
			print OUTPUTFILE "$rest\n";
		}
		else {  # no change needed
			print OUTPUTFILE "$line\n";
		}
	}
	close DATAFILE;
	for my $l (@breislines) {
		print OUTPUTFILE $l;
	}
	close OUTPUTFILE;
}

process_data_file('data.adj');
process_data_file('data.adv');
process_data_file('data.noun');
process_data_file('data.verb');
