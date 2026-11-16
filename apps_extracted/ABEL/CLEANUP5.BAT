@ECHO off
ECHO CLEANUP5: Deletes ABEL-EDU 5.03 work files. 
if (%1) == (all) goto L1
if (%1) == (ALL) goto L1
ECHO To delete .JED and .DOC files type CLEANUP5 ALL.
goto L2
:L1
if exist *.jed del *.jed
if exist *.pof del *.pof
if exist *.p8? del *.p8?
if exist *.doc del *.doc
:L2
if exist *.tmv del *.tmv
if exist *.sim del *.sim
if exist *.lst del *.lst
if exist *.bak del *.bak
if exist *.sav del *.sav
if exist *.tt? del *.tt?
if exist *.fus del *.fus
if exist *.dmc del *.dmc
if exist *.fit del *.fit
if exist *.fmp del *.fmp
if exist *.sel del *.sel
if exist *.sm? del *.sm?
if exist *.eq? del *.eq?
if exist *.err del *.err
if exist *.chp del *.chp
if exist *.fts del *.fts
if exist *.dec del *.dec
