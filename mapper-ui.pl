#!/usr/bin/perl

use strict;
use warnings;
use Locale::PO;
use Encode 'decode';

die "Usage: $0 [-p|-n]\n" unless ($#ARGV == 0 and $ARGV[0] =~ /^-[pn]/);
my $parens = ($ARGV[0] =~ /^-p/);
print "Parens only\n" if ($parens);
print "Non-interactive\n" if (!$parens);

sub my_warn
{
return 1;
}

sub userinput {
    my ($prompt) = @_;
    print "$prompt: ";
    $| = 1;          # flush
    $_ = getc;
    my $ans = $_;
    while (m/[^\n]/) {
		$_ = getc;
		$ans .= $_ if (m/[^\n]/);
	}
    return $ans;
}

my %pos_codes = ('1' => 'n',
				'2' => 'v',
				'3' => 'a',
				'4' => 'adv',
				'5' => 'a',
				);

my %hoa;
my %gloss;

sub get_glosses
{
	(my $fn, my $pos) = @_;
	# data.adj, data.adv, etc. are ASCII only
	open(TEMP, "<", $fn) or die "Could not open $fn: $!\n";
	while (<TEMP>) {
		chomp;
		unless (/^  /) {
			(my $offset, my $w_cnt, my $rest) = /^([0-9]{8}) [0-9][0-9] [nvasr] ([0-9a-f][0-9a-f]) (.+)$/;
			my $decimal_words = hex($w_cnt);
			my $synsetdescr='';
			for (my $i=0; $i < $decimal_words; $i++) {
				$rest =~ s/^([^ ]+) [0-9a-z] //;
				my $lemma=$1;
				$lemma =~ s/\([a-z]+\)$//; # s or a only:  "syntactic marker"
				$synsetdescr .= "$lemma, ";
			}
			(my $glss) = $rest =~ /[^|]+\| (.+)$/;
			$synsetdescr =~ s/, $/ -- /;
			$synsetdescr .= "($glss)";
			$gloss{"$pos|$offset"} = $synsetdescr;
		}
	}
	close TEMP;

}

get_glosses('data.adj','a');
get_glosses('data.adv','adv');
get_glosses('data.noun','n');
get_glosses('data.verb','v');

sub my_sort {
	(my $f_a) = $a =~ /^[^|]+\|[0-9]{8}\|([0-9]+)$/;
	(my $f_b) = $b =~ /^[^|]+\|[0-9]{8}\|([0-9]+)$/;
	if ($f_a == $f_b) {
		return $a cmp $b;  # just for well-definedness
	}
	else {
		return $f_b <=> $f_a;
	}
}

# ASCII only
open(SENSEINDEX, "<", "index.sense") or die "Could not open index.sense: $!\n";
while (<SENSEINDEX>) {
	chomp;
	(my $sense_key, my $offset, my $wnsensenumber, my $count) = /^([^ ]+) ([0-9]{8}) ([0-9]+) ([0-9]+)$/;
	(my $lemma, my $ss_type, my $lex_filenum, my $lex_id) = $sense_key =~ /^([^%]+)%([1-5]):([0-9][0-9]):([0-9][0-9])/;
	my $dict_pos = $pos_codes{$ss_type};
#	print "Pushing onto array at key $lemma|$dict_pos\n";
	push @{ $hoa{"$lemma|$dict_pos"} }, "$sense_key|$offset|$count";
}
close SENSEINDEX;

my $done_p = 0;
my $scanning_p = 1;
my $startmatch = 'a';
$startmatch = userinput("Starting pattern") if $parens;

my $aref;
{
local $SIG{__WARN__} = 'my_warn';
$aref = Locale::PO->load_file_asarray('en2wn.po');
}
open(OUTPUTPO, ">:utf8", "en2wn-new.po") or die "Could not output PO file: $!\n";
foreach my $msg (@$aref) {
	# comm's are all Irish, only about 10 msgid have accents (cliché, etc.)
	# and msgstr's are guaranteed pure ASCII - these are also the only
	# ones that are changed below so no need to encode before doing so
	my $id = decode('UTF-8',$msg->msgid());
	my $str = $msg->msgstr();
	$str =~ s/^"//;
	$str =~ s/"$//;
	my $comm = decode('UTF-8',$msg->automatic());
	if ($scanning_p) {
		$scanning_p = 0 if ($id =~ /^"$startmatch/);
	}
	if (defined($id) && defined($str) && defined($comm) && !$done_p && !$scanning_p) {
		if (!$parens or $id =~ /\(/) {
			if ($str eq '' or (!$parens and $str eq 'NULL')) {
				my $sid = $id;
				$sid =~ s/^"//;
				$sid =~ s/"$//;
				$sid =~ s/ \([^)]+\)$//;   # strip disambig string in parens
				(my $lemma, my $pos) = $sid =~ /^(.*)  (a|n|v|adv)$/;
				$lemma =~ s/ /_/g;
				if (exists($hoa{"\L$lemma|$pos"})) {
					my @cands = sort my_sort @{ $hoa{"\L$lemma|$pos"} };
					if (@cands == 1 and $id !~ /\(/ and $lemma !~ /^(cro|dod|Hessian|Leghorn|Mayo|PE|Provo|Tirolean|Unionist)$/) { 
#					this block is risky, only
#					reasonable if no need for disambig in IG (i.e. no parens)
#                   Not that much harder to just select the "1" for these
						my $key = $cands[0];
						$key =~ s/\|.*//;
						$str = $key;
					}
					elsif ($parens) {
						print "\n\nmsgid = $id needs a mapping to WN\n";
						print "$comm\nMenu:\n";
						my $count = 1;
						foreach my $cand (@cands) {
							(my $key, my $off, my $freq) = $cand =~ /^([^|]+)\|([0-9]{8})\|([0-9]+)$/;
							my $gl = $gloss{"$pos|$off"};
							print "($count) [N=$freq] $gl\n";
							$count++;
						}
						print "(n) NULL\n(s) Skip\n(q) Quit\n";
						my $ans = userinput("Your choice");
						if ($ans =~ /^[Qq]/) {
							$done_p = 1;
						}
						elsif ($ans =~ /^[Nn]/) {
							$str = 'NULL';
						}
						elsif ($ans =~ /^[Ss]/) {
							print "Leaving it unmapped.\n";
							$str = '';
						}
						elsif ($ans =~ /^[1-9][0-9]*$/) {
							my $keeper = $cands[$ans-1];
							$keeper =~ s/\|.+//;
							$str = $keeper;
						}
						else {
							print "Illegal input. Leaving it unmapped.\n";
							$str = '';
						}
					}
				}
				else {  # not in WN at all
					$str = 'NULL';
				}
			}
		}
	}
	if (defined($comm) and $comm ne '') {
		$comm =~ s/\n/\n#. /sg;
		print OUTPUTPO "#. $comm\n" unless ($comm eq '');
	}
	print OUTPUTPO "msgid $id\n";
	print OUTPUTPO "msgstr \"$str\"\n\n";
}
close OUTPUTPO;

exit 0;
