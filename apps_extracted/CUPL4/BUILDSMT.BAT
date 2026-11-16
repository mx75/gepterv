Echo off
Rename CUPL.DL OLDCUPL.DL
CBLD -B SMT.BLD
if errorlevel 1 goto errend
del OLDCUPL.DL
goto  end
:errend
Rename OLDCUPL.DL CUPL.DL
Echo.
Echo.
Echo An error has occured while trying to add the surface mount
Echo parts to the device library.
Echo.
Echo Make sure there is enough temporary disk space before
Echo running BUILDSMT again.
Echo.
:end
