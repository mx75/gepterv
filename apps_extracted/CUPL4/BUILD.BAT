Echo  off
CBLD -B CUPL.BLD
if errorlevel 1 goto errend
goto end
:errend
Echo .
Echo .
Echo An error has occured while building the device library.
Echo .
Echo Make sure there is enough disk space before trying again.
:end
