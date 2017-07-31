#!/bin/bash
#content:workflow for varscan2 CNV in tumor and normal analyse
#data：2017-07-27
#author： zhangqiaoshi
#email: zhangqshxxzz@gmial.com
#script for the varscan2 cnv  
#step1 samtools  flagstat  相应bam  # 为了计算dataratio
#step2 samtools  mpileup   相应bam
#step3 varscan2 copynumber --p-value 0.005 --min-coverage 30 --min-map-qual 20 --min-base-qual 20 --data-ratio dataratio
#step4 DNAcopy.R
#step5 mergeSegment
#step6 GISTIC2 对于多个样本的CNV分析的话，后续一般会用GISTIC/REA/CMDS 这些软件来分析 significant CNVs,这里用GISTIC2 ，参考网上各人方法与信息综合得到本分析CNV流程
#==========================path=============
start=`date +%s`
path_to_VarScan=/mnt/local-disk2/qszhang/biosoft
path_to_code=/mnt/local-disk2/qszhang/varscan_cnv_study/Breast_12_CNV
work=/mnt/local-disk2/qszhang/varscan_cnv_study/Breast_12_CNV
#============传递参数=======================
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
#===========================step01============
cd $work
mkdir $tumorname"CNV"$4
cd $tumorname"CNV"$4

samtools flagstat $3/$tumorname.sort.dedup.bam  > $tumorname.flagstat
samtools flagstat $3/$normalname.sort.dedup.bam > $normalname.flagstat


	tnum=$(grep -m 1 mapped $tumorname.flagstat | cut -f1 -d' ')
	cnum=$(grep -m 1 mapped $normalname.flagstat | cut -f1 -d' ')
	dataratio=$(echo "scale=2;$cnum/$tnum" | bc)   

#======================scale=2表示取小数点后两位==============


#======================$tumorname.cnvout生成$tumorname.cnvout.copynumber文件========================
java -jar $path_to_VarScan/VarScan.v2.4.0.jar copynumber $normal_pip $tumor_pip  $tumorname.cnvout --p-value 0.005 --min-coverage 30 --min-map-qual 20 --min-base-qual 20 --data-ratio $dataratio
#默认的Min coverage:   10   Min avg qual:   15    P-value thresh: 0.01  --mpileup 1（是单独的mpileup文件）  
#Did you normalize your data for differences in library size ( as you mentioned normal 30X and tumor 65X) ?
#VarScan2 copynumber has a parameter --data-ratio which accounts for this difference.
#from 这个说明， --data-ratio 这个参数可以用来修正正常样本和肿瘤样本测序数据间差别来着。  比例为 1  ，即正常和肿瘤样本平均覆盖度比例？ The normal/tumor input data ratio 
#所以首先我要计算下正常样本和肿瘤样本的平均覆盖度来着
#所以首先要做的是统计bam来着



java -jar $path_to_VarScan/VarScan.v2.4.0.jar copyCaller $tumorname.cnvout.copynumber --output-file $tumorname.cnvout.copynumber.called

Rscript $path_to_code/DNAcopy.R  $tumorname.cnvout.copynumber.called $tumorname.dnacopy.out $tumorname

#mergeSegment.pl使用注意
#1 mergeSegments.pl 的 134 行 和 361行 的两个变量 $sample 是对应的，两个都需要删除，不然结果会出错（output 内容和行号不对应，且 pvalue 错误）；
#2 mergeSegments.pl输入文件里面的chrosome 表示方法需要和 armSizes 文件里面的对应（如 chr1 对应 chr1， 1 对应 1），
#因为有的reference genome chrosome 没有 chr 前缀。
#3 去掉输入文件里面含有NA 值的行
#4 去掉输入文件里面 包含的一些 线粒体DNA（MT）或是 未知区域的DNA（GL*）的行

cat $tumorname.dnacopy.out| grep -v -e chrM -e random -e hap -e chrUn -e NA > $tumorname.dnacopy.out.segment


perl $path_to_code/mergeSegments.pl $tumorname.dnacopy.out.segment --ref-arm-sizes $path_to_code/armsize.txt --output-basename $tumorname.cnv




#find recurent CNV
#use gistic2 http://www.jianshu.com/p/eafa7e266806
#Step-3.1: Make marker position   -e chrX -e chrY -e chrX -e chrY  ID 染色体 起点
cat $tumorname.cnvout.copynumber | grep -v -e chrom -e chrM  -e random -e hap -e chrUn -e NA | awk 'BEGIN {OFS="\t"} { print "'$tumorname'",$1,$2 }' | sed 's/chr//g' > $tumorname.markerPosition

#Step-3.2: Make segment file. The output from mergeSegment.pl, which in this example with start with suffix “filteredOutput’ should be used to make segment file.
cat $tumorname.cnv.events.tsv | awk 'BEGIN {OFS="\t"} { print "'$tumorname'",$1,$2,$3,$6,$4 }' | grep -v -e chrM   -e random -e hap -e chrUn -e NA | sed 's/chr//g' > $tumorname.segmentedFile

markersfile=$tumorname.markerPosition

segfile=$tumorname.segmentedFile

refgenefile=/mnt/local-disk2/qszhang/biosoft-v1/GISTIC/refgenefiles/hg19.mat

basedir=$tumorname"_result_gistic"   #这个是输出结果的目录

mkdir $basedir

gp_gistic2_from_seg -b $basedir -seg $segfile -mk $markersfile -refgene $refgenefile -genegistic 1 -smallmem 1 -broad 1 -brlen 0.5 -conf 0.90 -armpeel 1 -savegene 1 -gcm extreme

end=`date +%s`
dif=$[ (end - start)/60 ]
echo "the varscan2 CNV run with "$dif"min."


