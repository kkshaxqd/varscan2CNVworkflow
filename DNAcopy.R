library("DNAcopy")
args <- commandArgs(TRUE)
cn <- read.table(args[1],header=T)
#pos <- round((cn[,2]+cn[,3])/2)  maybe not right for the GISTIC2.0
CNA.object <-CNA( genomdat = cn$adjusted_log_ratio, chrom = cn[,1], maploc = cn[,2], data.type = 'logratio', sampleid=args[3], presorted=TRUE)  #maploc = pos改为起点 sampleid改为参数3
CNA.smoothed <- smooth.CNA(CNA.object)
segs <- segment(CNA.smoothed, verbose=0, min.width=2)
segs2<-segs$output
segout<-paste(args[3],"cnvplotseg",sep=".")
write.table(segs2, file=segout, row.names=F, col.names=T, quote=F, sep="\t")
pdfout<-paste(args[3],"pdf",sep=".")
pdf(pdfout)
options(scipen=100)
plot(segs, plot.type="w")
#Plot each study by chromosome
#plot(segs, plot.type="s",cbys.nchrom=5)  #本例子里不是太好用，结果堆到一起，什么也看不出来。
#Plot each chromosome across studies (2 per page)
plot(segs, plot.type="c", cbys.layout=c(1,1), cbys.nchrom=2)
#Plot by plateaus
plot(segs, plot.type="p")
dev.off()
out=segments.p(segs, ngrid=100, tol=1e-6, alpha=0.05, search.range=100, nperm=1000) #增加, ngrid=100, tol=1e-6, alpha=0.05, search.range=100, nperm=1000
write.table(out, file=args[2], row.names=T, col.names=T, quote=F, sep="\t")
detach(package:DNAcopy)
