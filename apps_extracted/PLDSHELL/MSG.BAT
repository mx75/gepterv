@echo off
if not "%1" == "" goto :ok
echo   The filename prefix must be specified.  For example:
echo          MSG  LCD_MSG
goto :exit

:ok
if exist %1.in goto :update
copy template.in %1.in

:update
if exist %1.in goto :copy_ok
echo "copy template.in %1.in" failed.
goto :exit

:copy_ok
edit %1.in
FLS_DFLT < %1.in > %1.pds
PARPDS -d %1
LOCMIN %1
FITENGN %1
PENGN -port 1 -loc 0 -part epx780qc132 -ps %1

:exit
@echo on
