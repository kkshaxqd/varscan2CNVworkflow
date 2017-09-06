#!/bin/bash
#content:workflow for varscan2 CNV in tumor and normal analyse
#data��2017-07-27
#author�� zhangqiaoshi
#email: zhangqshxxzz@gmial.com
#script for the varscan2 cnv  
#step1 samtools  flagstat  ��Ӧbam  # Ϊ�˼���dataratio
#step2 samtools  mpileup   ��Ӧbam
#step3 varscan2 copynumber --p-value 0.005 --min-coverage 30 --min-map-qual 20 --min-base-qual 20 --data-ratio dataratio
#step4 DNAcopy.R
#step5 mergeSegment
#step6 GISTIC2 ���ڶ��������CNV�����Ļ�������һ�����GISTIC/REA/CMDS ��Щ��������� significant CNVs,������GISTIC2 ���ο����ϸ��˷�������Ϣ�ۺϵõ�������CNV����
#==========================path=============
start=`date +%s`
path_to_VarScan=/mnt/local-disk2/qszhang/biosoft
path_to_code=/mnt/local-disk2/qszhang/varscan_cnv_study/Breast_12_CNV
work=/mnt/local-disk2/qszhang/varscan_cnv_study/Breast_12_CNV
#============���ݲ���=======================
if [ $# -ne 4 ]
then
    echo "usage: $0 <tumorname> <normalname> <bam and mpileup path> <ID>"
    exit 65
fi
if [[ $3 =~ /$ ]]
 then
     echo "arg 3 can't contain the / in the end. It may be like this /mnt/local-disk2/xxx/Breast_cancer_12samples_analyse/ZLL-PEIDUI-NEW"
     exit 65
 fi	
 if [ ! -e $3/$1.mpileup ]
 then
     echo "can't find $1.mpileup: is $1 right and there have the .mpileup file?"
     exit 65
	 fi
 if [ ! -e $3/$1.sort.dedup.bam ]
 then
     echo "can't find $1.sort.dedup.bam: is $1 right and there have the .sort.dedup.bam file?"
     exit 65
	 fi
 if [ ! -e $3/$2.mpileup ]
 then
     echo "can't find $2.mpileup: is $2 right and there have the .mpileup file?"
     exit 65
	 fi
 if [ ! -e $3/$2.sort.dedup.bam ]
 then
     echo "can't find $2.sort.dedup.bam: is $2 right and there have the .sort.dedup.bam file?"
     exit 65	
 fi	
 
#==========================files============
tumorname=$1
tumor_pip=$3/$tumorname.mpileup
normalname=$2
normal_pip=$3/$normalname.mpileup	
ID=$4
#===========================step01============
cd $work
mkdir $tumorname"CNV"$4
cd $tumorname"CNV"$4

samtools flagstat $3/$tumorname.sort.dedup.bam  > $tumorname.flagstat
samtools flagstat $3/$normalname.sort.dedup.bam > $normalname.flagstat


	tnum=$(grep -m 1 mapped $tumorname.flagstat | cut -f1 -d' ')
	cnum=$(grep -m 1 mapped $normalname.flagstat | cut -f1 -d' ')
	dataratio=$(echo "scale=2;$cnum/$tnum" | bc)   

#======================scale=2��ʾȡС�������λ==============


#======================$tumorname.cnvout����$tumorname.cnvout.copynumber�ļ�========================
java -jar $path_to_VarScan/VarScan.v2.4.0.jar copynumber $normal_pip $tumor_pip  $tumorname.cnvout --p-value 0.005 --min-coverage 30 --min-map-qual 20 --min-base-qual 20 --data-ratio $dataratio
#Ĭ�ϵ�Min coverage:   10   Min avg qual:   15    P-value thresh: 0.01  --mpileup 1���ǵ�����mpileup�ļ���  
#Did you normalize your data for differences in library size ( as you mentioned normal 30X and tumor 65X) ?
#VarScan2 copynumber has a parameter --data-ratio which accounts for this difference.
#from ���˵���� --data-ratio ��������������������������������������������ݼ������š�  ����Ϊ 1  ������������������ƽ�����Ƕȱ����� The normal/tumor input data ratio 
#����������Ҫ��������������������������ƽ�����Ƕ�����
#��������Ҫ������ͳ��bam����



java -jar $path_to_VarScan/VarScan.v2.4.0.jar copyCaller $tumorname.cnvout.copynumber --output-file $tumorname.cnvout.copynumber.called

Rscript $path_to_code/DNAcopy.R  $tumorname.cnvout.copynumber.called $tumorname.dnacopy.out $ID

#mergeSegment.plʹ��ע��
#1 mergeSegments.pl �� 134 �� �� 361�� ���������� $sample �Ƕ�Ӧ�ģ���������Ҫɾ������Ȼ��������output ���ݺ��кŲ���Ӧ���� pvalue ���󣩣�
#2 mergeSegments.pl�����ļ������chrosome ��ʾ������Ҫ�� armSizes �ļ�����Ķ�Ӧ���� chr1 ��Ӧ chr1�� 1 ��Ӧ 1����
#��Ϊ�е�reference genome chrosome û�� chr ǰ׺��
#3 ȥ�������ļ����溬��NA ֵ����
#4 ȥ�������ļ����� ������һЩ ������DNA��MT������ δ֪�����DNA��GL*������

cat $tumorname.dnacopy.out| grep -v -e chrM -e random -e hap -e chrUn -e NA > $tumorname.dnacopy.out.segment


perl $path_to_code/mergeSegments.pl $tumorname.dnacopy.out.segment --ref-arm-sizes $path_to_code/armsize.txt --output-basename $tumorname.cnv




#find recurent CNV
#use gistic2 http://www.jianshu.com/p/eafa7e266806
#Step-3.1: Make marker position   -e chrX -e chrY -e chrX -e chrY  ID Ⱦɫ�� ���
#cat $tumorname.cnvout.copynumber | grep -v -e chrom -e chrM  -e random -e hap -e chrUn -e NA -e num_markers| awk 'BEGIN {OFS="\t"} { print "'$tumorname'",$1,$2 }' | sed 's/chr//g' > $tumorname.markerPosition

#Step-3.2: Make segment file. The output from mergeSegment.pl, which in this example with start with suffix ��filteredOutput�� should be used to make segment file.
#cat $tumorname.cnv.events.tsv | awk 'BEGIN {OFS="\t"} { print "'$tumorname'",$1,$2,$3,$6,$4 }' | grep -v -e chrM   -e random -e hap -e chrUn -e NA -e num_markers | sed 's/chr//g' > $tumorname.segmentedFile

cat $tumorname.cnvout.copynumber | grep -v -e chrom -e chrom -e chrM -e random -e hap -e chrUn |awk 'BEGIN{OFS="\t"}{print "'$ID'",$1,$2}'|sed 's/chr//g'>../$ID.newtest.markerPosition

cat $tumorname.dnacopy.out.segment | awk 'BEGIN {OFS="\t"} { print "'$ID'",$2,$3,$4,$5,$6 }' | grep -v -e chrM   -e random -e hap -e chrUn -e NA -e num_markers | sed 's/chr//g' > ../$ID.newtest.segmentedFile

cat ../$ID.newtest.segmentedFile | grep -v -e chrom -e chrom -e chrM -e random -e hap -e chrUn |perl -e  'while(<>){@aa=split/\t/,$_;print "$aa[0]\t$aa[1]\t$aa[2]\n$aa[0]\t$aa[1]\t$aa[3]\n"}'|sed 's/chr//g'>../$ID.newtest.markerPosition_test



markersfile=$ID.newtest.markerPosition

segfile=$ID.newtest.segmentedFile

refgenefile=/mnt/local-disk2/qszhang/biosoft-v1/GISTIC/refgenefiles/hg19.mat

basedir=$work/Breast_12_CNV_result_gistic   #�������������Ŀ¼

mkdir $basedir

gp_gistic2_from_seg -b $basedir -seg $segfile -mk $markersfile -refgene $refgenefile -genegistic 1 -smallmem 1 -broad 1 -brlen 0.5 -conf 0.90 -armpeel 1 -savegene 1 -gcm extreme

end=`date +%s`
dif=$[ (end - start)/60 ]
echo "the varscan2 CNV run with "$dif"min."


