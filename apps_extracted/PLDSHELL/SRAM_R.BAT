@ECHO OFF

rem     EPX780 SRAM read batch file
rem     This batch file is used to read a EPX780 SRAM
rem     into a .JED file
rem

rem     Check for empty command line
IF "%1" == "" GOTO :USAGE


rem     Read the EPX780 SRAM into a .JED file
@ECHO   Reading EPX780 SRAM into file %1.JED
pengn -port 1 -loc 0 -part epx780qc132 -rs %1
GOTO :END


:USAGE
@ECHO   The design filename must be specified without the extension.
@ECHO              Example:  SRAM_R [filename]
GOTO :END

:END
