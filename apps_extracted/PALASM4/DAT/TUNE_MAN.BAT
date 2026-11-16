rem echo off
IF "%1"=="" GOTO ERROR
IF "%1"=="1" set opt=-f 2/2/2/0/0
IF "%1"=="2" set opt=-f 2/2/1/0/0
IF "%1"=="3" set opt=-f 2/2/1/6/0
tune -k%PALASM%\EXE\PARSE.EXE %opt%
tune -k%PALASM%\EXE\BPP.EXE %opt%
tune -k%PALASM%\EXE\EXPAND.EXE %opt%
tune -k%PALASM%\EXE\MINIMIZE.EXE %opt%
tune -k%PALASM%\EXE\PLDSIM.EXE %opt%
tune -k%PALASM%\EXE\TREPL2.EXE %opt%
tune -k%PALASM%\EXE\TREMAIN.EXE %opt%
tune -k%PALASM%\EXE\ESP.EXE %opt%
tune -k%PALASM%\EXE\PART.EXE %opt%
GOTO END
:ERROR
echo Usage: tune_man [parameter]
echo        where parameter is the value 1, 2, or 3.
echo        1 being the most optimum tuning, 3 the least.
echo
echo i.e   tune_man 1
echo
:END
set opt=
exit
