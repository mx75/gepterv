@echo off
if not "%1" == "" goto :ok
echo   The filename prefix must be specified.  For example:
echo          MSG8160  LCD_MSG
goto :exit

:ok
if exist %1.in goto :update
copy lcd.pdi %1.in

:update
if exist %1.in goto :copy_ok
echo "copy lcd.pdi %1.in" failed.
goto :exit

:copy_ok
edit %1.in
lcd8160  %1.in
PARPDS -t %1
LOCMIN %1
FITENGN -pre keep_noprev %1
PENGN -loc 0 -part EPX8160QC208 -ps %1

:exit
@echo on
