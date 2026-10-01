@echo off
del *.tre
del *.log
del *.lis
del *.txt
del *.tmp
parse test4.pds -tre parse.tre -lis parse.lis -log parse.log
bpp parse.tre -log bpp.log -tre bpp.tre
expand bpp.tre -tre expand.tre -log expand.log
copy expand.tre minimize.tre
minimize -log minimize.log -tre minimize.tre >minimize.txt
copy minimize.tre palxpt.tre
palxpt palxpt.tre >palxpt.log
