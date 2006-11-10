#!/usr/bin/perl

use strict;
use warnings;

my %synsets;    # keys are "offset [nvars]"; vals are array refs
my %ptrs;       # keys are same

sub process_data_file
{
	(my $file) = @_;
	open(DATAFILE, "<", $file) or die "Could not open $file: $!\n";
	while (<DATAFILE>) {
		chomp;
		unless (/^  /) {
			(my $synset_offset, my $ss_type, my $w_cnt, my $rest) = /^([0-9]{8}) ([nvasr]) ([0-9]+) (.+)$/;
			for (my $i=0; $i < $w_cnt; $i++) {
				$rest =~ s/^([^ ]+) //;
				push @{$synsets{"$synset_offset $ss_type"}}, $1;
			}
			$rest =~ s/^([0-9]{3}) //;
			my $p_cnt = $1;
			for (my $i=0; $i < $p_cnt; $i++) {
				$rest =~ s/^([^ ]+ [0-9]{8} [nvasr] [0-9a-f]{4}) //;
				my $ptr = $1;
				push @{$ptrs{"$synset_offset $ss_type"}}, $ptr if ($ptr =~ /0000$/);
			}
		}
	}
	close DATAFILE;
}

process_data_file('ga-data.adj');
process_data_file('ga-data.adv');
process_data_file('ga-data.noun');
process_data_file('ga-data.verb');

my %posnames = ( 'n' => 'ainmfhocal',
				'v' => 'briathar',
				'a' => 'aidiacht',
				'r' => 'dobhriathar',
				's' => 'aidiacht',
				);

my %crossrefnames = (
						# nouns
						'@' => 'aicme',
						'@i' => 'aicme',
						'~' => 'fo-aicme',
						'~i' => 'fo-aicme',
						'#m' => 'bailiúchán',  # member holonym   "collection"
						'#s' => 'comhiomlán',  # substance holonym "aggregate"
						'#p' => 'iomlán',      # part holonym    "whole"
						'%m' => 'ball',        # member meronym
						'%s' => 'substaint',   # substance meronym
						'%p' => 'páirt',       # part meronym
						'='  => 'tréith',      # attribute
						';c' => 'ábhar',       # domain
						'-c' => 'gaol',        # in this domain
						';r' => 'réigiún',     # region
						'-r' => 'gaol',        # in this region
						# verbs only
						'*'  => 'impleacht',   # entailment
						'>'  => 'toradh',      # cause
						'$'  => 'gaol',        # verb group
						# adjs only
						'&'  => 'gaol',        # similar to
#						'='  => 'cuspóir',     # attribute
#						'^'  => 'gaol',        # see also

						'!'   => 'NULL',     # antonyms, lexical only
						'+'   => 'NULL',     # derivational, lexical only
						';u'  => 'NULL',    # usage: really should be lexical?
						'-u'  => 'NULL',    # usage: really should be lexical?
						'^'   => 'NULL',    # error - should be lexical "fall" 
						'<'   => 'NULL',    # participle, lexical only
						'\\'  => 'NULL',    # pertainym, lexical only
										    # (derivational for adv.)

					);

my %answer;
foreach my $set (keys %synsets) {
	(my $off, my $pos) = $set =~ /^([0-9]{8}) ([nvars])$/;
	foreach my $focal (@{$synsets{$set}}) {
		my @printable;
		push @printable, "($posnames{$pos})";
		foreach my $focal2 (@{$synsets{$set}}) {  # add all simple synonyms
			if ($focal ne $focal2) {
				my $copy = $focal2;
				$copy =~ s/\+.+$//;
				$copy =~ s/_/ /g;
				push @printable, $copy;
			}
		}
		if (exists($ptrs{$set})) {    # follow pointers and add qualified wrds
			foreach my $p (@{$ptrs{$set}}) {
				$p =~ /^([^ ]+) ([0-9]{8} [nvasr]) 0000$/;
				my $ptr_symbol = $1;  # see man wninput(5WN)
				my $crossrefkey = $2;
				my $crname = $crossrefnames{$ptr_symbol};
				if ($pos =~ /^[sa]$/) {
					$crname = 'gaol' if ($ptr_symbol eq '^');
					$crname = 'cuspóir' if ($ptr_symbol eq '=');
				}
				if ($crname ne 'NULL' and exists($synsets{$crossrefkey})) {
					foreach my $cr (@{$synsets{$crossrefkey}}) {
						my $toadd = $cr;
						$toadd =~ s/\+.+$//;
						$toadd =~ s/_/ /g;
						$toadd =~ s/$/ ($crname)/; 
						push @printable, $toadd;
					}
				}
			}
		}
		my $disp_f = $focal;
		$disp_f =~ tr/A-ZÁÉÍÓÚ/a-záéíóú/;
		push @{$answer{$disp_f}}, join('|', @printable) unless (@printable == 1);
	}
}
open(OUTPUTFILE, ">", 'th_ga_IE_v2.dat') or die "Could not open th_ga_IE_v2.dat: $!\n";
print OUTPUTFILE "ISO8859-1\n";
foreach my $f (sort keys %answer) {
	my $fprint = $f;
	$fprint =~ s/\+.+$//;
	print OUTPUTFILE "$fprint|".scalar(@{$answer{$f}})."\n";
	foreach my $sense (@{$answer{$f}}) {
		print OUTPUTFILE "$sense\n";
	}
}
close OUTPUTFILE;
exit 0;
