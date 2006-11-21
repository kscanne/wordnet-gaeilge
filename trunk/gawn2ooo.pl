#!/usr/bin/perl

use strict;
use warnings;

my %synsets;    # keys are "offset [nvars]"; vals are array refs
my %ptrs;       # keys are same

# -l = LaTeX output
# -o = OOo output
die "Usage: $0 [-o|-l]\n" unless ($#ARGV == 0 and $ARGV[0] =~ /^-[ol]/);

my $ooo=0;
my $latex=0;
my $outputfile;
if ($ARGV[0] =~ /^-o/) {
	$ooo=1;
	$outputfile = 'th_ga_IE_v2.dat';
}
elsif ($ARGV[0] =~ /^-l/) {
	$latex=1;
	$outputfile = 'sonrai.tex';
}

#######################################################################
###  Start by reading in the ga-data.* files into "synsets" and "ptrs" hashes
###  This step is independent of the eventual output format
#######################################################################

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
						'=a' => 'cuspóir',     # attribute (really =)
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

my %plrefnames = (
						# nouns
						'@' => 'Aicmí',
						'@i' => 'Aicmí',
						'~' => 'Fo-Aicmí',
						'~i' => 'Fo-Aicmí',
						'#m' => 'Bailiúcháin',  # member holonym   "collection"
						'#s' => 'Comhiomláin',  # substance holonym "aggregate"
						'#p' => 'Iomláin',      # part holonym    "whole"
						'%m' => 'Baill',        # member meronym
						'%s' => 'Substaintí',   # substance meronym
						'%p' => 'Páirteanna',       # part meronym
						'='  => 'Tréithe',      # attribute
						';c' => 'Ábhair',       # domain
						'-c' => 'Gaolta',        # in this domain
						';r' => 'Réigiúin',     # region
						'-r' => 'Gaolta',        # in this region
						# verbs only
						'*'  => 'Impleachtaí',   # entailment
						'>'  => 'Torthaí',      # cause
						'$'  => 'Gaolta',        # verb group
						# adjs only
						'&'  => 'Gaolta',       # similar to
						'=a' => 'Cuspóirí',    # attribute (really =)
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

sub ig_to_output_pos
{
	(my $x) = @_;
	$x =~ s/^n([fb])/$1/;   # f1,f3,f4,  b2,b3,b4
	$x =~ s/^[ns]$/af/;        # af
	$x =~ s/^a$/aid/;       # no declension
	$x =~ s/^adv$/db/;      # no declension
	$x =~ s/^v/br/;         # briathar
	$x =~ s/^npl.*/iol/;    # iolra
	return $x;
}

sub for_output
{
	(my $x) = @_;
	$x =~ s/\+.+$//;
	$x =~ s/_/ /g;
	return $x;
}

sub for_output_pos
{
	(my $x) = @_;
	$x =~ s/\+[0-9]+\+/, /;
	$x =~ s/_/ /g;
	return $x;
}

sub cross_ref_designation
{
	(my $x, my $pos) = @_;
	my $lookup;
	if ($ooo) {
		$lookup = \%crossrefnames;
	}
	elsif ($latex) {
		$lookup = \%plrefnames;
	}
	my $crname = $lookup->{$x};
	if ($pos =~ /^[sa]$/) {
		$crname = $lookup->{'$'} if ($x eq '^');
		$crname = $lookup->{'=a'} if ($x eq '=');
	}
	return $crname;
}

#######################################################################
###  Next, set up the "answer" data structure depending on structure of
###  the desired output file
#######################################################################
my %answer;

if ($ooo) {
	foreach my $set (keys %synsets) {
		(my $pos) = $set =~ /^[0-9]{8} ([nvars])$/;
		foreach my $focal (@{$synsets{$set}}) {
			my @printable;
			(my $igpos) = $focal =~ /^[^+]+\+[^+]+\+(.+)$/;
			$igpos = ig_to_output_pos($igpos);
	#		push @printable, "($posnames{$pos})";
			push @printable, "($igpos)";
			foreach my $focal2 (@{$synsets{$set}}) {  # add all simple synonyms
				push @printable, for_output($focal2) if ($focal ne $focal2);
			}
			if (exists($ptrs{$set})) { # follow pointers and add qualified wrds
				foreach my $p (@{$ptrs{$set}}) {
					$p =~ /^([^ ]+) ([0-9]{8} [nvasr]) 0000$/;
					my $ptr_symbol = $1;  # see man wninput(5WN)
					my $crossrefkey = $2;
					my $crname = cross_ref_designation($ptr_symbol,$pos);
					if ($crname ne 'NULL' and exists($synsets{$crossrefkey})) {
						foreach my $cr (@{$synsets{$crossrefkey}}) {
							push @printable, for_output($cr)." ($crname)" unless ($focal eq $cr);
						}
					}
				}
			}
			my $disp_f = $focal;
			$disp_f =~ tr/A-ZÁÉÍÓÚ/a-záéíóú/;
			push @{$answer{$disp_f}}, join('|', @printable) unless (@printable == 1);
		}
	}
}
elsif ($latex) {
	foreach my $set (keys %synsets) {
		(my $pos) = $set =~ /^[0-9]{8} ([nvars])$/;
		my @ss = @{$synsets{$set}};
		my $first = shift @ss;
		foreach my $focal (@ss) {
			push @{$answer{$first}{'_syn'}}, $focal;
			push @{$answer{$focal}{'_cross'}}, $first;
			(my $igpos) = $focal =~ /^[^+]+\+[^+]+\+(.+)$/;
			$igpos = ig_to_output_pos($igpos);
			if (exists($ptrs{$set})) { # follow pointers
				foreach my $p (@{$ptrs{$set}}) {
					$p =~ /^([^ ]+) ([0-9]{8} [nvasr]) 0000$/;
					my $ptr_symbol = $1;  # see man wninput(5WN)
					my $crossrefkey = $2;
					my $crname = cross_ref_designation($ptr_symbol,$pos);
					if ($crname ne 'NULL' and exists($synsets{$crossrefkey})) {
						foreach my $cr (@{$synsets{$crossrefkey}}) {
							push @{$answer{$first}{$crname}}, $cr unless ($first eq $cr);
						}
					}
				}
			}
		}
	}
}

#######################################################################
###  Now dump to file
#######################################################################
{
use locale;
open(OUTPUTFILE, ">", $outputfile) or die "Could not open $outputfile: $!\n";
if ($ooo) {
	print OUTPUTFILE "ISO8859-1\n";
	foreach my $f (sort keys %answer) {
		print OUTPUTFILE for_output($f)."|".scalar(@{$answer{$f}})."\n";
		foreach my $sense (@{$answer{$f}}) {
			print OUTPUTFILE "$sense\n";
		}
	}
}
elsif ($latex) {
	foreach my $f (sort keys %answer) {
		print OUTPUTFILE for_output_pos($f)."\n";
		my $count = 1;
		if (exists($answer{$f}{'_syn'})) {
			print OUTPUTFILE "1. Comhchiallaigh: ".join(', ', @{$answer{$f}{'_syn'}}).".\n";
			for my $crtype (keys %{$answer{$f}}) {
				unless ($crtype =~ /^_/) {   # _cross, _syn excluded
					print OUTPUTFILE "   $crtype: ".join(', ', @{$answer{$f}{$crtype}}).".\n";
				}
			}
			$count++;
		}
		for my $cr (@{$answer{$f}{'_cross'}}) {
			print OUTPUTFILE "$count. -> $cr.\n";
			$count++;
		}
		print OUTPUTFILE "\n\n";
	}
}

close OUTPUTFILE;
}


exit 0;
