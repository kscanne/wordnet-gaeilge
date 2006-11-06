#!/usr/bin/perl

use strict;
use warnings;
use Locale::PO;

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
	open(TEMP, "<", $fn) or die "Could not open $fn: $!\n";
	while (<TEMP>) {
		chomp;
		unless (/^  /) {
			(my $offset, my $glss) = /^([0-9]{8})[^|]+\| (.+)$/;
			$gloss{"$pos|$offset"} = $glss;
		}
	}
	close TEMP;

}

get_glosses('data.adj','a');
get_glosses('data.adv','adv');
get_glosses('data.noun','n');
get_glosses('data.verb','v');

open(SENSEINDEX, "<", "index.sense") or die "Could not open index.sense: $!\n";
while (<SENSEINDEX>) {
	chomp;
	(my $sense_key, my $offset, my $wnsensenumber, my $count) = /^([^ ]+) ([0-9]{8}) ([0-9]+) ([0-9]+)$/;
	(my $lemma, my $ss_type, my $lex_filenum, my $lex_id) = $sense_key =~ /^([^%]+)%([1-5]):([0-9][0-9]):([0-9][0-9])/;
	my $dict_pos = $pos_codes{$ss_type};
#	print "Pushing onto array at key $lemma|$dict_pos\n";
	push @{ $hoa{"$lemma|$dict_pos"} }, "$sense_key|$offset";
}
close SENSEINDEX;

my $done_p = 0;

my $aref;
{
local $SIG{__WARN__} = 'my_warn';
$aref = Locale::PO->load_file_asarray('en2wn.po');
}
open(OUTPUTPO, ">", "en2wn-new.po") or die "Could not output PO file: $!\n";
foreach my $msg (@$aref) {
	my $id = $msg->msgid();
	my $str = $msg->msgstr();
	my $comm = $msg->comment();
	if (defined($id) && defined($str) && defined($comm) && !$done_p) {
		if ($str and $id and $id =~ /\(/) {
			if ($str eq '""') {
				my $sid = $id;
				$sid =~ s/^"//;
				$sid =~ s/"$//;
				$comm =~ s/^"//;
				$comm =~ s/"$//;
				$sid =~ s/ \([^)]+\)$//;   # strip disambig string in parens
				(my $lemma, my $pos) = $sid =~ /^(.*)  (a|n|v|adv)$/;
				$lemma =~ s/ /_/g;
				if (exists($hoa{"\L$lemma|$pos"})) {
					my @cands = @{ $hoa{"\L$lemma|$pos"} };
					if (@cands == 1) {
						my $key = $cands[0];
						$key =~ s/\|.*//;
						$msg->msgstr($key);
					}
					else {
						print "\n\nmsgid = $id needs a mapping to WN\n";
						print "$comm\nMenu:\n";
						my $count = 1;
						foreach my $cand (@cands) {
							(my $key, my $off) = $cand =~ /^([^|]+)\|([0-9]{8})$/;
							my $gl = $gloss{"$pos|$off"};
							print "($count) $gl\n";
							$count++;
						}
						print "(n) NULL\n(s) Skip\n(q) Quit\n";
						my $ans = userinput("Your choice");
						if ($ans =~ /^[Qq]/) {
							$done_p = 1;
						}
						elsif ($ans =~ /^[Nn]/) {
							$msg->msgstr('NULL');
						}
						elsif ($ans =~ /^[Ss]/) {
							print "Leaving it unmapped.\n";
						}
						elsif ($ans =~ /^[1-9][0-9]*$/) {
							my $keeper = $cands[$ans-1];
							$keeper =~ s/\|.+//;
							$msg->msgstr($keeper);
						}
						else {
							print "Illegal input. Leaving it unmapped.\n";
						}
					}
				}
				else {  # not in WN at all
					$msg->msgstr("NULL");
				}
			}
		}
	}
	print OUTPUTPO $msg->dump;
}
close OUTPUTPO;

exit 0;