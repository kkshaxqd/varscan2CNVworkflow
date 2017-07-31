# varscan2CNVworkflow

the workflow for varscan2 CNV analyse

因为varscan的CNV分析步骤众所周知的问题，官网提供的mergeSegments.pl脚本的bug，原来的varscan cnv分析很难利用，现通过研究，综合如下网址，建立一个新的适合varscan cnv分析的流程

### script for the varscan2 cnv  

### step1 samtools  flagstat  相应bam  #为了计算dataratio

### step2 samtools  mpileup   相应bam

### step3 varscan2 copynumber --p-value 0.005 --min-coverage 30 --min-map-qual 20 --min-base-qual 20 --data-ratio dataratio

### step4 DNAcopy.R

### step5 mergeSegment

value of log for amplification and deletion is amplification  > 0.25 and deletion < -0.25

-0.25< log2 value <0.25  is  neutral

### step6 anno segment file 

### step7 GISTIC2 对于多个样本的CNV分析的话，后续一般会用GISTIC/REA/CMDS 这些软件来分析 significant CNVs,这里用GISTIC2 ，参考网上各人方法与信息综合得到本分析CNV流程

#### GISTIC2  need many segment file for analyse , you may need the arraylistfile.txt and cnvfile.txt

```
cnvfile.txt
SNP_A-1511055	Variation_4091	
SNP_A-1641749	Variation_2158	
SNP_A-1641750	Variation_2503	
SNP_A-1641752	Variation_3868	
SNP_A-1641771	Variation_3746	
.......	
SNP_A-1641803	Variation_3762	

arraylistfile.txt
array
primary_GBM_2
primary_GBM_4
secondary_GBM_1
.......
primary_GBM_14
primary_GBM_15
primary_GBM_17
secondary_GBM_5

markersfile.txt
SNP_A-1738457	1	328296
SNP_A-1658232	1	1435232
........
SNP_A-1676440	1	2719853

segmentationfile.txt
secondary_GBM_6	23	80591269	80836448	3	-3.565646
secondary_GBM_6	23	80841379	81217783	9	-2.489093
.........
primary_GBM_30	3	48603	184937009	7379	0.049753
primary_GBM_30	3	184957186	185413394	6	-0.9328935
```

So the arraylistfile.txt is the sample name  ,but the cnvfile.txt is what?

```
Option #1: A two column, tab-delimited file with an optional header row. The marker names given in this file must match the marker names given in the markers file. The CNV identifiers are for user use and can be arbitrary. The column headers are: (1) Marker Name and (2) CNV Identifier
```

So you can arbitray it....


附录PS:

参考网址：

http://wp.zxzyl.com/?p=156

https://www.biostars.org/p/158408/

for GISTIC2 install

http://portals.broadinstitute.org/cgi-bin/cancer/publications/pub_paper.cgi?mode=view&paper_id=216&p=t

http://www.jianshu.com/p/eafa7e266806

等等。
