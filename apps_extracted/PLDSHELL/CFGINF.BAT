@echo off

echo Getting Configuration Info...

echo ######################## CONFIGURATION DETAILS #############  > config.inf
echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo ###########################  DOS VERSION ################### >> config.inf
echo.                                                             >> config.inf
ver                                                               >> config.inf

echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo ###########################  CONFIG.SYS #################### >> config.inf
echo.                                                             >> config.inf
type c:\config.sys                                                >> config.inf

echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo ##########################  AUTOEXEC.BAT ################### >> config.inf
echo.                                                             >> config.inf
type c:\autoexec.bat                                              >> config.inf

echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo ##########################  ENVIRONMENT #################### >> config.inf
echo.                                                             >> config.inf
set                                                               >> config.inf

echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo ########################  MEMORY SETTINGS ################## >> config.inf
echo.                                                             >> config.inf
mem /c                                                            >> config.inf

echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo ######################## MISC INFORMATION ################## >> config.inf
echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo Customer Name : ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo Phone Number  : _(____)_____________________________________ >> config.inf
echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo Version of PLDShell(tm): ___________________________________ >> config.inf
echo.                                                             >> config.inf
echo SID of PLDShell(tm)    : ___________________________________ >> config.inf
echo.                                                             >> config.inf
echo Offending Module       : ___________________________________ >> config.inf
echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo Machine Brand/Model : ______________________________________ >> config.inf
echo.                                                             >> config.inf
echo Description of  ____________________________________________ >> config.inf
echo.       Problem:                                              >> config.inf
echo                 ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo                 ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo                 ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo                 ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo                 ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo.                                                             >> config.inf
echo Other Comments: ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo                 ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo                 ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo                 ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo                 ____________________________________________ >> config.inf
echo.                                                             >> config.inf
echo                 ____________________________________________ >> config.inf

echo.
echo.
echo The information was saved in 'CONFIG.INF'.   Please print the file
echo and return it when reporting memory/configuration issues.
echo.
