#!/usr/bin/perl
#
# count_SNPS_indels.pl
# parses a nucmer SNP table to count the number of SNPs and indels in a genome alignment
 
use strict;
use warnings;
 
open (INFILE, $ARGV[0]) or die "Cannot open infile as ARGV[0]";
open (OUTFILE, ">$ARGV[1]") or die "Cannot open outfile as ARGV[1]";
 
# read through nucmer snps file, count snps and indels
 
my $indels = 0;
my $snps = 0;
while (my $line = <INFILE>){ 
    my @linearray = split /\s+/, $line;
    next unless (scalar @linearray == 16); 
    if ($linearray[2] eq "." or $linearray[3] eq "."){
        $indels++;
    }
    else {
        $snps++;
    }
}
close INFILE;
 
# print to output file
 
print OUTFILE "Number of SNPS = $snps\n";
print OUTFILE "Number of indels = $indels\n";
 
close OUTFILE;
