REM Builds ABEL device selector architecture only data base 
if exist lib4\mini\devsel.dbd del lib4\mini\devsel.*
if exist lib4\mini\sorter.dbd del lib4\mini\sorter.*
devbld -i LIB4\BDS\ARCH.BDS -data lib4\mini
devmenu -o lib4\mini\abelsel.mnu -database lib4\mini 
