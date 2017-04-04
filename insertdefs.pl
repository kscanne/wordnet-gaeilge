#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Locale::PO;
use Encode qw(decode);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my %idtodef;

sub process_po {
	(my $fn) = @_;
	my $aref = Locale::PO->load_file_asarray($fn);
	for my $msg (@$aref) {
		my $id = $msg->msgstr();
		my $str = decode("utf8", $msg->msgstr());
		my $ctxt = $msg->msgctxt();
		if (defined($id) and defined($str) and defined($ctxt) and $str ne '""') {
			$str =~ s/^"//;
			$str =~ s/"$//;
			$ctxt =~ s/^"//;
			$ctxt =~ s/"$//;
			$idtodef{$ctxt} = $str;
		}
	}
}

process_po('ga-data.adj.po');
process_po('ga-data.adv.po');
process_po('ga-data.noun.po');
process_po('ga-data.verb.po');

while (<STDIN>) {
	if (m/<Synset id="lsg-([0-9]+-.)/) {
		my $id = $1;
		$id =~ s/-/ /;
		if (exists($idtodef{$id})) {
			my $def = $idtodef{$id};
			s/$/\n      <Definition>$def<\/Definition>/;
		}
	}
	print;
}

exit 0;
