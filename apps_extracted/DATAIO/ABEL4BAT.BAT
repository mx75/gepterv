@echo off
rem
rem   The arguments expected by this batch file are:
rem
rem            %1  - source file name (without the .ABL extension)
rem         %2-%4  - AHDL2PLA, PLAOPT, FUSEASM or JEDSIM options
rem
rem   Additional command line options for ABEL programs may be
rem   specified either in the ABEL-HDL source file (in an OPTIONS
rem   statement) or in the ABELBAT2.BAT file.
rem
if "%1" == "" goto error
if not exist %1.abl goto error1
if not "%5" == "" echo Warning: too many arguments - %5 ignored.
if not "%6" == "" echo Warning: too many arguments - %6 ignored.
if not "%7" == "" echo Warning: too many arguments - %7 ignored.
if not "%8" == "" echo Warning: too many arguments - %8 ignored.
if not "%9" == "" echo Warning: too many arguments - %9 ignored.
echo  ABEL Batch Utility - Copyright (c) 1990 Data I/O Corp. All Rights Reserved
ahdl2pla %1 -list -batch %2 %3 %4
if errorlevel == 1 goto end
command /c %1.bat %2 %3 %4
del %1.bat
goto end
:error
echo  Usage: abel4bat abel_file [option1 option2 option3]
goto end
:error1
echo  Could not find input file "%1.abl"
:end

