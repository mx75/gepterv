@echo off
REM Uses the standard MS-DOS FIND.EXE command.
if NOT (%1) == () goto L1
echo FINDDEV4 string - Searches DEVICES.TXT and list lines matching the string.
echo Example: FINDDEV4 P20RA10  Would list all lines containing P20RA10
goto EXIT
:L1
echo	NOTE: Fitter options:    N = No fitter support for this device
echo                          O = Fitter is optional for this device
echo                          R = Fitter is required for this device
echo
echo MFG               Part              Type    Pkg Pins Device     Fitter
if not (%ABEL4DEV%) == () find "%1" %ABEL4DEV%\devices.txt
if     (%ABEL4DEV%) == () find "%1" c:\dataio\lib4\devices.txt
:EXIT

