@ECHO OFF

rem     EPX780 programming batch file
rem     This batch file is used to load a .JED file into
rem     A EPX780 SRAM.
rem

rem     Check for empty command line
IF "%1" == "" GOTO :USAGE


rem     Check to see if file exist
IF NOT EXIST %1.JED GOTO :NO_FILE


rem     Load the .JED file into the device.
@ECHO   Loading %1.JED into EPX780 SRAM
pengn -port 1 -loc 0 -part epx780qc132 -ps %1
GOTO :END


:NO_FILE
@ECHO   I/O Error -- Can't open file %1.JED
@ECHO   Check for valid filename and path.
GOTO :USAGE

:USAGE
@ECHO   The design filename must be specified, without the extension.
@ECHO              Example:  SRAM_W [filename]
GOTO :END

:END
