library("DNAcopy")
args <- commandArgs(TRUE)
cn <- read.table(args[1],header=T)
#pos <- round((cn[,2]+cn[,3])/2)  maybe not right for the GISTIC2.0
CNA.object <-CNA( genomdat = cn$adjusted_log_ratio, chrom = cn[,1], maploc = cn[,2], data.type = 'logratio', sampleid=args[3], presorted=TRUE)  #maploc = pos改为起点 sampleid改为参数3
CNA.smoothed <- smooth.CNA(CNA.object)
segs <- segment(CNA.smoothed, verbose=0, min.width=2)
out=segments.p(segs, ngrid=100, tol=1e-6, alpha=0.05, search.range=100, nperm=1000) #增加, ngrid=100, tol=1e-6, alpha=0.05, search.range=100, nperm=1000
write.table(out, file=args[2], row.names=F, col.names=T, quote=F, sep="\t")
detach(package:DNAcopy)
