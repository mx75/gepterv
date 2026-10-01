@echo off
call ..\..\deltmp.bat
parse test4.pds -tre parse.tre -lis parse.lis -log parse.log
bpp parse.tre -log bpp.log -tre bpp.tre
expand bpp.tre -tre expand.tre -log expand.log
rem copy expand.tre minimize.tre
rem minimize -log minimize.log -tre minimize.tre >minimize.txt
copy expand.tre bpp2in.tre
bpp bpp2in.tre -log bpp2.log -tre bpp2out.tre
copy bpp2out.tre minimize.tre
minimize -log minimize.log -tre minimize.tre >minimize.txt
fitr minimize.tre >fitr.txt
