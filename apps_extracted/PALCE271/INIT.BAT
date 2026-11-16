echo off
if exist PLACE.SAV goto DELFILE1
goto END
:DELFILE1
del place.sav
if exist PDS-3.INI goto DELFILE2
goto END
:DELFILE2
del pds-3.ini
:END
place
