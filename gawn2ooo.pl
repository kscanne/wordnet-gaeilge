#!/usr/bin/perl

use strict;
use warnings;

use Storable;  # for morcego dump
use Encode qw(from_to);   # morcego wants utf8

my %synsets;    # keys are "offset [nvars]"; vals are array refs
my %ptrs;       # keys are same

# -l = LaTeX output
# -o = OOo output
# -t = txt output
# -m = output for morcego
die "Usage: $0 [-l|-m|-o|-t|-g]\n" unless ($#ARGV == 0 and $ARGV[0] =~ /^-[moltg]/);

my $ooo=0;
my $latex=0;
my $text=0;
my $morcego=0;
my $graphviz=0;
my $outputfile;
if ($ARGV[0] =~ /^-o/) {
	$ooo=1;
	$outputfile = 'th_ga_IE_v2.dat';
}
elsif ($ARGV[0] =~ /^-l/) {
	$latex=1;
	$outputfile = 'sonrai.tex';
}
elsif ($ARGV[0] =~ /^-t/) {
	$text=1;
	$outputfile = 'sonrai.txt';
}
elsif ($ARGV[0] =~ /^-m/) {
	$morcego=1;
	$outputfile = 'morcego.hash';
}
elsif ($ARGV[0] =~ /^-g/) {
	$graphviz=1;
	$outputfile = 'lsg.dot';
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

# nb2 -> b2, etc.
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

my %answer;

sub for_output
{
	(my $x) = @_;
	my $key = $x;
	if ($key =~ s/\.[0-9]+\+/+/) {
		$x = $key if (scalar(@{$answer{$key}{'_main'}})==1);
	}
	$x =~ s/\+.+$//;
	$x =~ s/_/ /g;
	return $x;
}


# input is "tocht+7+nf3+OD77", outputs nice LaTeX form with citation
sub for_output_pos_latex
{
	(my $x) = @_;
	(my $w, my $pos, my $ref) = $x =~ /^([^+]+)\+[0-9]+\+([^+]+)\+(.+)$/;
	$w =~ s/_/ /g;
	my $ans="{\\textbf{$w,}}";
	$ans .= "\\cite{$ref}" unless ($ref =~ /^OD77b?/);
	$ans .=	" \\textit{".ig_to_output_pos($pos)."}";
	return $ans;
}

# input is "tocht+7+nf3+OD77", outputs "tocht, f3"
sub for_output_pos
{
	(my $x) = @_;
	$x =~ s/^([^+]+)\+[0-9]+\+([^+]+)\+.+$/"$1, ".ig_to_output_pos($2)/e;
	$x =~ s/_/ /g;
	return $x;
}

# input is "tocht+7+nf3+OD77", outputs "tocht+7+f3+OD77"
sub fix_pos
{
	(my $x) = @_;
	$x =~ s/^([^+]+\+[0-9]+)\+([^+]+)\+(.+)$/"$1+".ig_to_output_pos($2)."+$3"/e;
	return $x;
}

# input is "tocht+7+nf3+OD77", outputs "f3"
sub outputpos
{
	(my $x) = @_;
	(my $igpos) = $x =~ /^[^+]+\+[0-9]+\+([^+]+)\+/;
	return ig_to_output_pos($igpos);
}

sub hypertarget
{
	(my $x) = @_;
	$x =~ s/\.[0-9]+\+/+/;   # don't point to subentries (for now)
	$x =~ s/[+_]//g;
	return $x;
}

sub letter
{
	(my $x) = @_;
	(my $ans) = $x =~ /^(.)/;
	$ans =~ tr/a-záéíóú/A-ZÁÉÍÓÚ/;
	$ans =~ tr/ÁÉÍÓÚ/AEIOU/;
	return $ans;
}

sub for_hyperlink_output
{
	(my $x) = @_;
	return '\hyperlink{'.hypertarget($x).'}{'.for_output($x).'}';
}



sub cross_ref_designation
{
	(my $x, my $pos) = @_;
	my $lookup;
	if ($ooo or $morcego or $graphviz) {
		$lookup = \%crossrefnames;
	}
	elsif ($latex or $text) {
		$lookup = \%plrefnames;
	}
	if ($graphviz) {
		# alternatively, not starting with ~,%,- or others that are always NULL
		if ($x =~ m/^[\;\@\#\=\*\>\$\&]/ and $x ne ';u') {
			$x = '@';  # => not NULL
		}
		else {
			$x = '!';  # => NULL
		}
	}
	my $crname = $lookup->{$x};
	if ($pos =~ /^[sa]$/) {
		$crname = $lookup->{'$'} if ($x eq '^');
		$crname = $lookup->{'=a'} if ($x eq '=');
	}
	return $crname;
}

# input is number between 0 and 99, output is 00,01,02,...,09,10,11,...
sub two_digit
{
	(my $x) = @_;
	$x =~ s/^/0/ if ($x < 10);
	return $x;
}

#######################################################################
###  Next, set up the "answer" data structure depending on structure of
###  the desired output file
#######################################################################

#  The ooo "answer" is simple - hash of arrays, one key for each headword, and
#  the array contains the printable |-separated strings for each sense

#  More complicated for latex, etc.  It's first a hash with two keys
#  '_main' and '_cross' for the main entries and cross ref entries 
#  respectively.  $answer{'_cross'} is an array with the cross refs.
#  $answer{'_main'} is an array, one for each main entry (usually 1),
#  of hashes with keys _syn, Aicmí, Fo-Aicmí, etc.    These point to arrays!

if ($ooo) {
	foreach my $set (keys %synsets) {
		(my $pos) = $set =~ /^[0-9]{8} ([nvars])$/;
		foreach my $focal (@{$synsets{$set}}) {
			my @printable;
	#		push @printable, "($posnames{$pos})";
			push @printable, "(".outputpos($focal).")";
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
elsif ($graphviz) {
	foreach my $set (keys %synsets) {
		(my $uid, my $pos) = $set =~ /^([0-9]{8} ([nvars]))$/;
		$uid =~ s/ //;
		my $i = 0;
		foreach my $focal (@{$synsets{$set}}) {
			my $focalout = for_output_pos($focal);
			my $j = 0;
			foreach my $focal2 (@{$synsets{$set}}) {  # add all simple synonyms
				my $focal2out = for_output_pos($focal2);
				push @{$answer{$uid.two_digit($i).':'.$focalout}}, $uid.two_digit($j).':'.$focal2out if ($i < $j);
				$j++;
			}
			$i++;
		}
		my $synsethead = $synsets{$set}->[0];
		my $headout = for_output_pos($synsethead);
		if (exists($ptrs{$set})) { # follow pointers and add qualified wrds
			foreach my $p (@{$ptrs{$set}}) {
				$p =~ /^([^ ]+) ([0-9]{8} [nvasr]) 0000$/;
				my $ptr_symbol = $1;  # see man wninput(5WN)
				my $crossrefkey = $2;
				my $crname = cross_ref_designation($ptr_symbol,$pos);
				if ($crname ne 'NULL' and exists($synsets{$crossrefkey})) {
					my $cr = $synsets{$crossrefkey}->[0];
					my $crout = for_output_pos($cr);
					$crossrefkey =~ s/ //;
					push @{$answer{$uid.'00:'.$headout}}, $crossrefkey.'00:'.$crout;
				}  #  non-lexical pointer, and points to an existing synset
			}  # loop over each pointer
		}  # there are pointers
	}  # loop over synsets
}
elsif ($morcego) {
	foreach my $set (keys %synsets) {
		(my $pos) = $set =~ /^[0-9]{8} ([nvars])$/;
		my $synsetsize = scalar @{$synsets{$set}};
		my $synsethead = $synsets{$set}->[0];
		$synsethead =~ s/^([^+]+)\+[0-9]+/$1+00/;
		my $utfsynsethead = fix_pos($synsethead);
		from_to($utfsynsethead,"iso-8859-1","utf-8");
		my $prev = '';
		foreach my $focal (@{$synsets{$set}}) {
			my $utffocal=fix_pos($focal);
			from_to($utffocal,"iso-8859-1","utf-8");
			push @{$answer{$utffocal}}, $utfsynsethead;
			push @{$answer{$utfsynsethead}}, $utffocal;
			unless ($prev) {
				my $p=$synsets{$set}->[$synsetsize-1];
				$prev=fix_pos($p);
				from_to($prev,"iso-8859-1","utf-8");
			}
			unless ($utffocal eq $prev) {  # <=> synsetsize!=1?
				push @{$answer{$utffocal}}, $prev;
				push @{$answer{$prev}}, $utffocal;
				$prev = $utffocal;
			}
		}
		if (exists($ptrs{$set})) { # follow pointers and add qualified wrds
			foreach my $p (@{$ptrs{$set}}) {
				$p =~ /^([^ ]+) ([0-9]{8} [nvasr]) 0000$/;
				my $ptr_symbol = $1;  # see man wninput(5WN)
				my $crossrefkey = $2;
				my $crname = cross_ref_designation($ptr_symbol,$pos);
				if ($crname ne 'NULL' and exists($synsets{$crossrefkey})) {
					my $cr = $synsets{$crossrefkey}->[0];
					$cr =~ s/^([^+]+)\+[0-9]+/$1+00/;
					my $utfcr = fix_pos($cr);
					from_to($utfcr,"iso-8859-1","utf-8");
					unless ($synsethead eq $cr) {
						push @{$answer{$utfsynsethead}}, $utfcr;
						push @{$answer{$utfcr}}, $utfsynsethead;
					}
				}  #  non-lexical pointer, and points to an existing synset
			}  # loop over each pointer
		}  # there are pointers
	}  # loop over synsets
}
elsif ($latex or $text) {
	my %hwhash;  # keys look like "10292737 n", vals like "póilín.1+4+nf4+OD77"
	foreach my $set (keys %synsets) {
		(my $pos) = $set =~ /^[0-9]{8} ([nvars])$/;
		my @ss = @{$synsets{$set}};
		my $first = shift @ss;
		my $numofthismainentry = 1;
		if (exists($answer{$first}{'_main'})) {
			$numofthismainentry += scalar(@{$answer{$first}{'_main'}});
		}
		my $crossref = $first;
		$crossref =~ s/\+/.$numofthismainentry+/;
		$hwhash{$set}=$crossref;
		my %topush;
		foreach my $focal (@ss) {
			push @{$topush{'_syn'}}, $focal;
			push @{$answer{$focal}{'_cross'}}, $crossref;
		}
		if (exists($ptrs{$set})) { # follow pointers
			foreach my $p (@{$ptrs{$set}}) {
				$p =~ /^([^ ]+) ([0-9]{8} [nvasr]) 0000$/;
				my $ptr_symbol = $1;  # see man wninput(5WN)
				my $crossrefkey = $2;
				my $crname = cross_ref_designation($ptr_symbol,$pos);
				if ($crname ne 'NULL' and exists($synsets{$crossrefkey})) {
					# used to loop through @{$synsets{$crossrefkey}} and push
					push @{$topush{$crname}}, $crossrefkey unless ($first eq $synsets{$crossrefkey}->[0]);
				}
			}
		}
		push @{$answer{$first}{'_main'}}, \%topush;
	}
	foreach my $f (keys %answer) {
		for my $hr (@{$answer{$f}{'_main'}}) {
			for my $crtype (sort keys %{$hr}) {
				unless ($crtype =~ /^_/) { # so just Aicmí, Fo-Aicmí, etc.
					my $len = scalar(@{$hr->{$crtype}});
					for (my $j=0; $j<$len; $j++) {
						$hr->{$crtype}->[$j] = $hwhash{$hr->{$crtype}->[$j]};
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

# stuff below attempts to mimic OD77 sort order.
# Can see some of the choices illustrated by looking up
# "leis", "sí", "caoch", etc.
#  adverbs are unclear since often bundled with n or adj in OD77
# Only other difference is that OD77 puts capitalized words before
# uncapitalized (Ceilteach before ceilteach, Áiseach before áiseach),
# which is the opposite of standard unix latin-1 locale behavior,
# which we're relying on.   Diacritics work correctly though.

my %possort = ( 'f' => 0,
				'b' => 1,
				'iol' => 2,
				'af' => 3,
				'aid' => 4,
				'a' => 5,
				'br' => 6,
				'db' => 7,
				);

sub hw_sort {
	(my $w_a, my $c_a, my $pos_a, my $ref_a) = $a =~ /^([^+]+)\+([0-9]+)\+([^+]+)\+(.+)$/;
	(my $w_b, my $c_b, my $pos_b, my $ref_b) = $b =~ /^([^+]+)\+([0-9]+)\+([^+]+)\+(.+)$/;
	if ($w_a eq $w_b) {
		if ($pos_a eq $pos_b) {
			if ($c_a == $c_b) {
				if ($ref_a eq $ref_b) {
					print STDERR "Problem with $a\n";
				}
				return $ref_a cmp $ref_b;
			}
			else {
				return $c_b <=> $c_a;
			}
		}
		else {
			(my $ch_a) = $pos_a =~ /^([^0-9]+)/;
			(my $ch_b) = $pos_b =~ /^([^0-9]+)/;
			my $n_a = $possort{ig_to_output_pos($ch_a)};
			my $n_b = $possort{ig_to_output_pos($ch_b)};
			if ($n_a == $n_b) {
				return $pos_a cmp $pos_b;
			}
			else {
				return $n_a <=> $n_b;
			}
		}
	}
	else {
		return $w_a cmp $w_b;
	}
}

if ($morcego) {
	store \%answer, $outputfile;
	exit 0;
}

open(OUTPUTFILE, ">", $outputfile) or die "Could not open $outputfile: $!\n";
if ($ooo) {
	print OUTPUTFILE "ISO8859-1\n";
	foreach my $f (sort hw_sort keys %answer) {
		print OUTPUTFILE for_output($f)."|".scalar(@{$answer{$f}})."\n";
		foreach my $sense (@{$answer{$f}}) {
			print OUTPUTFILE "$sense\n";
		}
	}
}
elsif ($graphviz) {
	my %labels;
	print OUTPUTFILE "graph G {\n";
	foreach my $f (keys %answer) {
		(my $id, my $label) = $f =~ /^([^:]+):(.+)$/;
		$id =~ tr/nvsar/01234/;
		$labels{$id} = $label;
		foreach my $link (@{$answer{$f}}) {
			(my $lid, my $llabel) = $link =~ /^([^:]+):(.+)$/;
			$lid =~ tr/nvsar/01234/;
			$labels{$lid} = $llabel;
			print OUTPUTFILE "    $id -- $lid;\n";
		}
	}
#	foreach my $g (keys %labels) {
#		print OUTPUTFILE "    $g [label=\"$labels{$g}\"];\n";
#	}
	print OUTPUTFILE "}\n";
}
elsif ($latex) {
	my $prev = '';
	my $curr;
	foreach my $f (sort hw_sort keys %answer) {
		$curr = letter($f);	
		if ($curr ne $prev) {
			unless  ($curr =~ /^[KXYZ]$/) {
				my $topr = $curr;
				$topr = 'JK' if ($curr eq 'J');
				$topr = 'WXYZ' if ($curr eq 'W');
				print OUTPUTFILE '\chapter*{'.$topr."}\n";
				print OUTPUTFILE '\addcontentsline{toc}{chapter}{'.$topr."}\n";
			}
			$prev = $curr;
		}
		print OUTPUTFILE '\setlength{\hangindent}{10pt}'."\n";
		print OUTPUTFILE '\noindent\hypertarget{'.hypertarget($f).'}'.for_output_pos_latex($f)."\n";
		print OUTPUTFILE '\markboth{'.for_output($f).'}{'.for_output($f)."}\n";
		my $count = 1;
		for my $hr (@{$answer{$f}{'_main'}}) {  # often empty
			if ($count == 1) {
				if (exists($answer{$f}{'_cross'}) or scalar(@{$answer{$f}{'_main'}})>1) {
					print OUTPUTFILE '\textbf{'."$count.}\n";
				}
			}
			else {
				print OUTPUTFILE '\\\\ \textbf{'."$count.}\n";
			}
			print OUTPUTFILE '--- \textsc{Comhchiall}: ';
			if (exists($hr->{'_syn'})) {
				print OUTPUTFILE join(', ', map(for_hyperlink_output($_), @{$hr->{'_syn'}})).".\n";
			}
			else {
				print OUTPUTFILE "n/a/f.\n";
			}
			for my $crtype (sort keys %{$hr}) {
				unless ($crtype =~ /^_/) {   # _syn excluded
					print OUTPUTFILE '--- \textsc{'.$crtype.'}: '.join(', ', map(for_hyperlink_output($_), @{$hr->{$crtype}})).".\n";
				}
			}
			$count++;
		}
		if (exists($answer{$f}{'_cross'})) {
			if ($count == 1) {
				print OUTPUTFILE '--- \textsc{Féach}: ';
			}
			else {
				print OUTPUTFILE '\\\\ \textbf{'."$count.}\n".'--- \textsc{Agus féach}: ';
			}
			print OUTPUTFILE join(', ', map(for_hyperlink_output($_), @{$answer{$f}{'_cross'}})).".\n";
		}
		print OUTPUTFILE "\n\n";

	}
}
elsif ($text) {
	foreach my $f (sort hw_sort keys %answer) {
		print OUTPUTFILE for_output_pos($f)."\n";
		my $count = 1;
		for my $hr (@{$answer{$f}{'_main'}}) {  # often empty
			print OUTPUTFILE " $count. Comhchiallaigh: ";
			if (exists($hr->{'_syn'})) {
				print OUTPUTFILE join(', ', map(for_output($_), @{$hr->{'_syn'}})).".\n";
			}
			else {
				print OUTPUTFILE "n/a/f.\n";
			}
			for my $crtype (sort keys %{$hr}) {
				unless ($crtype =~ /^_/) {   # _syn excluded
					print OUTPUTFILE "    $crtype: ".join(', ', map(for_output($_), @{$hr->{$crtype}})).".\n";
				}
			}
			$count++;
		}
		for my $cr (@{$answer{$f}{'_cross'}}) {
			print OUTPUTFILE " $count. -> ".for_output($cr).".\n";
			$count++;
		}
		print OUTPUTFILE "\n\n";
	}
}

close OUTPUTFILE;
}  # see "use locale;" above


exit 0;
