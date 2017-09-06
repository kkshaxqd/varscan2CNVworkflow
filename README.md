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


usage: sh varscancnvworkflow.sh <tumorname> <normalname> <bam and mpileup path> <ID>


附录PS:

参考网址：

http://wp.zxzyl.com/?p=156

https://www.biostars.org/p/158408/

for GISTIC2 install

http://portals.broadinstitute.org/cgi-bin/cancer/publications/pub_paper.cgi?mode=view&paper_id=216&p=t

http://www.jianshu.com/p/eafa7e266806

等等。
