#!/usr/bin/perl

use strict;
use warnings;
use Locale::PO;

sub my_warn
{
return 1;
}

# -y ("yes") writes wn2ga.txt
# -n ("no") writes unmapped-irish.txt
die "Usage: $0 [-y|-n]\n" unless ($#ARGV == 0 and $ARGV[0] =~ /^-[yn]/);

my $aref;
my %en2wn;  # simple hash matching the en2wn.po file
my %final;  # hash of arrays; keys are WN sense_keys, values are 
            # array refs containing list of ga words with this sense
my $unmapped=($ARGV[0] eq "-n");

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
			$en2wn{$id} = $str;
		}
	}
}

open (IG, '/home/kps/seal/ig7') or die "couldn't open IG data: $!\n";

while (<IG>) {
	chomp;
	if (/^([^.]+)\. ([^ ]+(?: \([^)]+\))?)? (\[[^]]+\])(?:, \[[^]]+\])*: (.*)$/) {
		my $w = $1;
		my $p = $2;
		my $ref = $3;
		my $d = $4;

		next unless $p;
		next if ($p =~ /\([dg](s|pl)\)/);
		next if ($p =~ /\(caite/);   # fhaca, etc.
		$p =~ s/ \(.*$//;
		#normalize POS tags
		my $porig = $p;
		$p =~ s/^([nv]).*/$1/;
		$p =~ s/[0-9 ].*//;
		$p =~ s/^s$/n/;
		if ($p =~ /^([nav]|adv)$/) {
			#normalize defs
			$d =~ s/, \[[^]]+\]//g;     # kill glosses
			$d =~ s/, /,/g;
			$d =~ s/\.$//;

			# tidy reference
			$ref =~ s/^\[//;
			$ref =~ s/\]$//;
			$ref =~ s/;.+$//;

			my @defs = split /,/, $d;
			# ok means it will appear in final thesaurus, but also
			# set to true if it's [in phrase] so no expectation it should
			my $ok=($d =~ /^\[in phrase\]/);
			for my $def (@defs) {
				if ($def =~ /\)$/) {
					$def =~ s/\(/ $p (/;
				}
				else {
					$def =~ s/$/  $p/;
				}
				if (exists($en2wn{$def})) {
					push @{ $final{$en2wn{$def}} }, "$w+".scalar(@defs)."+$porig+$ref";
					$ok=1;
				}
			}  # loop over en defs
			if (!$ok and $unmapped) {
				print "$w+".scalar(@defs)."+$porig+$ref: $d\n";
			}
		}  # n,a,v,adv
	}   # if line is parsed ok
} # loop over ig7

close IG;

unless ($unmapped) {
	foreach my $sense_key (keys %final) {
		print $sense_key.'|'.join(',',@{$final{$sense_key}})."\n";
	}
}

exit 0;
