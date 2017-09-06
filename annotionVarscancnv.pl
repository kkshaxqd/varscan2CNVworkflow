#!/usr/bin/perl -w
###注释varscan  cnv, use segments.file
use strict;

my ($varscancnvfile,$Tumor_name,$genecoordfile);
my (@info,$sample,$cnvlog,$CNV_Type,$chr,$start,$stop,$num_markers,$kb,$line,@uc_local);
my $gene;
my $uc_chr ;
my $uc_start ;
my $uc_stop ;
my $uc_id ;
my $uc_chr_num;
my %string;

if ($ARGV[0])
{
	$varscancnvfile = $ARGV[0];
	if ($varscancnvfile =~ /(.*)\.segmentedFile/ )
		{
		$Tumor_name = $1; 
		}
	else
		{
		print "\n\n*************************\nERROR: $ARGV[0] MUST BE .segmentedFile which varscan2 mergeSegment.pl product and  deal with.\n annotionVarscancnv.pl XXXX.segmentedFile gene_coord.txt.txt > xxxxx.anno\n\n*************************\n\n";
		die;
		}
	}
else
	{
	print "\n\n*************************\nERROR: Must provide varscan cnv and gene_coord files.\n To use like this: annotionVarscancnv.pl XXXX.segmentedFile gene_coord.txt > XXXX.anno \n\n*************************\n\n";
	die;
	}

if ($ARGV[1])
{
	$genecoordfile = $ARGV[1];
	if ($genecoordfile =~ /gene_coord\.txt/ )
		{
		}
	else
		{
		print "\n\n*************************\nERROR: $ARGV[1] MUST BE gene_coord which varscan2 mergeSegment.pl product and  deal with.\n annotionVarscancnv.pl XXXX.segmentedFile gene_coord.txt.txt > xxxxx.anno\n\n*************************\n\n";
		die;
		}
	}
else
	{
	print "\n\n*************************\nERROR: Must provide varscan cnv and gene_coord files.\n To use like this: annotionVarscancnv.pl XXXX.segmentedFile gene_coord.txt > XXXX.anno \n\n*************************\n\n";
	die;
	}

print "SAMPLE\tCHR\tSTART\tSTOP\tNum_markers\tLog_cnv\tCNV_Type\tKB\tGENE\n";
open INFILE1, "$varscancnvfile" or die "couldn't open $varscancnvfile:$!\n";

while (<INFILE1>)
       	{
       	chomp;
	my @info = split('\t', $_);
     $sample=$info[0];
	 $cnvlog=$info[5];
	if($cnvlog>0.25){$CNV_Type="AMP"}elsif($cnvlog<-0.25){$CNV_Type="DEL"}elsif($cnvlog>=-0.25 && $cnvlog<=0.25 ){$CNV_Type="neutral"}

		$chr = $info[1];
		$start = $info[2];
		$stop = $info[3];
		$num_markers= $info[4];
		if($start && $stop){$kb=sprintf("%.2f",($stop-$start)/1000);}else{$kb="-";}
		
		$line=$_."\t".$CNV_Type."\t".$kb;
		
		open INFILE2, "$genecoordfile" or die "couldn't open $genecoordfile\n"; #gene_coords.txt是多转录本的，这个是最长基因位点的都算。

		while (<INFILE2>)
		    {
		    chomp;
			@uc_local = split('\t', $_);
			$gene = $uc_local[3];
			$uc_chr = $uc_local[0];
			$uc_start = $uc_local[1];
			$uc_stop = $uc_local[2];
			$uc_id = $sample."-".$start."-".$stop;


			if ($uc_chr =~ /chr([\dXY]+)/)
				{
				$uc_chr_num = $1;
				if ($chr eq $uc_chr_num)
					{
					###重确定条件如果CNV大的话，覆盖多个基因的情况。将匹配到的基因覆盖到后面
					if ($start <= $uc_stop && $stop >= $uc_start)   
						{  
						if( $string{$uc_id} )
						{
						$string{$uc_id}=$string{$uc_id}."|".$gene ;
						#print "1\n";
						}
						else{$string{$uc_id}=$line."\t".$gene ;  }
						
						}
					else{}
					}
				}
			}
		close INFILE2;
}		

close INFILE1;

 foreach my $id ( sort {$a cmp $b } keys %string )
 {
 print "$string{$id}\n";

 }


























