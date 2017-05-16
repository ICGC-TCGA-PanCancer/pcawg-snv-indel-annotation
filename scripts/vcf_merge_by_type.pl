#! /usr/bin/perl

use strict;
use String::Random;
use Getopt::Long;
# this creates a merge VCF by variant type e.g. SNV, indel, SV
# this produces a very simple VCF and also handles merging multiple variants
# into a single line

my $info = {};
my $d = {};


# Inputs: the filenames for SNVs for Broad, Sanger, DKFZ/EMBL, MusE;
# the filenames for INDELs for Broad, Sanger, DKFZ/EMBL, SMuFin;
# the filenames for SVs for Broad, Sanger, DKFZ/EMBL;
# the path to the root directory where all the files are;
# the path to the output directory.

# Call this script like this:
# perl vcf_merge_by_type.pl --broad_snv <broad SNV filename> \
#                           --sanger_snv <sanger SNV filename> \
#                           --de_snv <DKFZ/EMBL SNV filename> \
#                           --muse_snv <MUSE SNV filename> \
#                           --broad_sv <broad SV filename> \
#                           --sanger_sv <sanger SV filename> \
#                           --de_sv <DKFZ/EMBL SV filename> \
#                           --broad_indel <broad INDEL filename> \
#                           --sanger_indel <sanger INDEL filename> \
#                           --de_indel <DKFZ/EMBL INDEL filename> \
#                           --smufin_indel <SMuFin INDEL filename> \
#                           --indir /datastore/path_to_above_VCFs/ \
#                           --outdir /datastore/output_directory

my ($broad_snv, $sanger_snv, $de_snv, $muse_snv,
        $broad_indel, $sanger_indel, $de_indel,
        $broad_sv, $sanger_sv, $de_sv, $smufin_indel,
        $in_dir, $out_dir);

GetOptions ("broad_snv=s" => \$broad_snv,
			"sanger_snv=s" => \$sanger_snv,
			"dkfz_embl_snv=s" => \$de_snv,
			"muse_snv=s" => \$muse_snv,
			"broad_sv=s" => \$broad_sv,
			"sanger_sv=s" => \$sanger_sv,
			"dkfz_embl_sv=s" => \$de_sv,
			"broad_indel=s" => \$broad_indel,
			"sanger_indel=s" => \$sanger_indel,
			"dkfz_embl_indel=s" => \$de_indel,
			"smufin_indel=s" => \$smufin_indel,
			"indir=s" => \$in_dir,
			"outdir=s" => \$out_dir);

my @snv = (split(/,/,$broad_snv), split(/,/,$sanger_snv), split(/,/,$de_snv), split(/,/,$muse_snv));
my @indel = (split(/,/,$broad_indel), split(/,/,$sanger_indel), split(/,/,$de_indel), split(/,/,$smufin_indel));
my @sv = (split(/,/,$broad_sv), split(/,/,$sanger_sv), split(/,/,$de_sv));

process($out_dir."/snv.clean", @snv);
process($out_dir."/indel.clean", @indel);
process($out_dir."/sv.clean", @sv);

sub process {

  my $out_file = shift;
  my @files = @_;

  $d = {};

  $info = {};
  my $header = <<"EOS";
##fileformat=VCFv4.1
##variant_merge=$out_file
#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO
EOS

  open my $OUT, ">$out_file.vcf" or die;

  print $OUT $header;

  # process file into hash
  foreach my $i (@files) {
  	if ((defined $i) && !($i eq ""))
  	{
	    print "processing file $i\n";
	    process_file($in_dir."/".$i, $OUT);
  	}
  }

  # write hash
  foreach my $chr (sort keys %{$d}) {
    foreach my $pos (sort keys %{$d->{$chr}}) {
      print $OUT $d->{$chr}{$pos}."\n";
    }
  }
  close $OUT;

  sort_and_index($out_file);

}

sub sort_and_index {

  my ($file) = @_;
  my @parts = split /\//, $file;
  my $filename = $parts[-1];
  my $rnd = new String::Random;
  my $randomString = $rnd->randregex('\w{16}');
  my $cmd = " vcf-sort $file.vcf > $out_dir/$filename.sorted.vcf; \\
        echo zipping_and_indexing ; \\
        bgzip -f -c $out_dir/$filename.sorted.vcf > $out_dir/$filename.sorted.vcf.gz ; \\
        tabix -p vcf $out_dir/$filename.sorted.vcf.gz ";

  print "$cmd\n";

  my $result = system($cmd);

  print "Status of sort: $result\n";
}

sub process_file {
  my ($file, $OUT) = @_;
  # Input files might not be zipped...
  if ($file =~ m/.*gz/ )
  {
    open(IN, "zcat $file |") or die;
  }
  else
  {
    open(IN, "cat $file |") or die;
  }
  while(<IN>) {
    chomp;
    next if (/^#/);
    # FIXME
    # next if (!/PASS/ || /tier/);
    my @a = split /\t/;
    my $payload = "$a[0]\t$a[1]\t.\t$a[3]\t$a[4]\t$a[5]\t$a[6]\t.";
    $d->{$a[0]}{$a[1]} = $payload;
  }
  close IN;
}
