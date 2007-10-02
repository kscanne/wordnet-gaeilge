#!/usr/bin/perl

use strict;
use warnings;

my $test_p = 0;
my $batchsize = 15;
my $dis = '/home/kps/math/code/data/Ambiguities/EN';

my %poscode = ( 'n' => 0,
				'v' => 1,
				'a' => 2,
				'adv' => 3,
				);

open(COUNT, "<", "line.txt") or die "Could not open line.txt for reading: $!\n";
chomp(my $start = <COUNT>); 
close COUNT;

my $nextstart = $start + $batchsize;
my %gfs;

open(EN, "<", $dis) or die "Could not open $dis for reading: $!\n";
chomp(my $en_count = <EN>);
for (my $i=0; $i<$en_count; $i++) {
	chomp(my $w = <EN>);
	chomp(my $p = <EN>);
	chomp(my $sensecount = <EN>);
	my $key = "$w;$p";
	for (my $j=0; $j<$sensecount; $j++) {
		chomp(my $s = <EN>);
		push @{$gfs{$key}}, $s;
	}
	chomp(my $dummy=<EN>);  # blank line
}
close EN;

open(CURR, ">", "current.txt") or die "Could not open current.txt: $!\n";
open(GFS, "<", "disambig.txt") or die "Could not open disambig.txt: $!\n";
while (<GFS>) {
	if (($. >= $start and $. < $nextstart) or $test_p) {
		chomp;
		(my $word, my $pos, my $senses) = /^([A-Za-z].+) ([nav]|adv)\. \[((?:[A-Za-z'-]+, )+[A-Za-z'-]+)\]$/;
		if (defined($word) and defined($pos) and defined($senses)) {
			my $key = $word.';'.$poscode{$pos};
			if (exists($gfs{$key})) {
				print STDERR "Problem on line $.: $word  $pos already exists\n";
			}
			else {
				$senses =~ s/, /,/g;
				push @{$gfs{$key}}, split(/,/,$senses);
				print CURR "^$word  $pos \\(\n";
				$en_count++;
			}
		}
		else {
			print STDERR "Problem parsing on line $.\n";
		}
	}
}
close GFS;
close CURR;

sub my_sort {
	(my $w_a, my $pos_a) = $a =~ /^([^;]+);([0123])$/;
	(my $w_b, my $pos_b) = $b =~ /^([^;]+);([0123])$/;
	if ($w_a eq $w_b) {
		return $pos_a <=> $pos_b;
	}
	else {
		return $w_a cmp $w_b;
	}
}

exit 0 if $test_p;

open(EN, ">", $dis) or die "Could not open $dis for writing: $!\n";
print EN "$en_count\n";
foreach my $k (sort my_sort keys %gfs) {
	my $printkey=$k;
	$printkey =~ s/;/\n/;
	print EN "$printkey\n".scalar @{$gfs{$k}}."\n";
	foreach my $s (@{$gfs{$k}}) {
		print EN "$s\n";
	}
	print EN "\n";  # blank
}
close EN;

open(COUNT, ">", "line.txt") or die "Could not open line.txt for writing: $!\n";
print COUNT $nextstart, "\n";
close COUNT;

exit 0;
