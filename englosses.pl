#!/usr/bin/perl

use strict;
use warnings;
use Locale::PO;

sub my_warn
{
return 1;
}

my $aref;
my %senseindex;  # simple hash matching sense indices with byte offsets
my %offsettoen;  # keys are "offset;pos", vals are arrays of
				# c/en English headwords matching that synset

sub process_data_file
{
	(my $file) = @_;
	open(DATAFILE, "<", $file) or die "Could not open $file: $!\n";
	while (<DATAFILE>) {
		chomp;
		unless (/^  /) {
			(my $synset_offset, my $lex_filenum, my $ss_type, my $w_cnt, my $rest) = /^([0-9]{8}) ([0-9][0-9]) ([nvasr]) ([0-9a-f][0-9a-f]) (.+)$/;
			my $decimal_words = hex($w_cnt);
			for (my $i=0; $i < $decimal_words; $i++) {
				$rest =~ s/^([^ ]+) ([0-9a-z]) //;
			}
			$rest =~ s/^([0-9]{3}) //;
			my $p_cnt = $1;
			for (my $i=0; $i < $p_cnt; $i++) {
				$rest =~ s/^([^ ]+) ([0-9]{8}) ([nvasr]) ([0-9a-f]{4}) //;
			}
			my $gloss = $rest;
			$gloss =~ s/^[^|]*\| //;   # kills frames for verbs too
			my $key = $synset_offset.$ss_type;
			if (exists($offsettoen{$key})) {
				foreach my $en (@{$offsettoen{$key}}) {
					print "$en|$gloss\n";
				}
			}
		}
	}
	close DATAFILE;
}

open(SENSEINDEX, "<", "index.sense") or die "Could not open index.sense: $!\n";
while (<SENSEINDEX>) {
    chomp;
    (my $sense_key, my $offset) = /^([^ ]+) ([0-9]{8}) [0-9]+ [0-9]+$/;
	$senseindex{$sense_key} = $offset;
}
close SENSEINDEX;

my %pos_codes = ('1' => 'n',
                '2' => 'v',
				 '3' => 'a',
				'4' => 'r',
				'5' => 's',
);


{
local $SIG{__WARN__} = 'my_warn';
$aref = Locale::PO->load_file_asarray('en2wn.po');
}
foreach my $msg (@$aref) {
	my $id = $msg->msgid();
	my $str = $msg->msgstr();
	if (defined($id) && defined($str)) {
		if ($str and $id and $str ne '""' and $str ne '"NULL"') {
			$id =~ s/^"//;
			$id =~ s/"$//;
			$str =~ s/^"//;
			$str =~ s/"$//;
			(my $lemma, my $ss_type, my $lex_filenum, my $lex_id) = $str =~ /^([^%]+)%([1-5]):([0-9][0-9]):([0-9][0-9])/;
			if (exists($senseindex{$str})) {
				my $key = $senseindex{$str}.$pos_codes{$ss_type};
				push @{$offsettoen{$key}}, $id;
			}
		}
	}
}

process_data_file('data.adj');
process_data_file('data.adv');
process_data_file('data.noun');
process_data_file('data.verb');

exit 0;
