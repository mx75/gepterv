rem Echo  off
if exist temp*.dl erase temp*.dl
ARCE  PLD20.ARC
ARCE  PLD24.ARC
Rename  PLD20.DL  TEMP1.DL
Rename  PLD24.DL  TEMP2.DL
CBLD -B CUPL.BLD
Del TEMP1.DL
Del TEMP2.DL
Rename TEMP3.DL TEMP1.DL
ARCE  PLD28.ARC
Rename PLD28.DL TEMP2.DL
CBLD -B CUPL.BLD
Del TEMP1.DL
Del TEMP2.DL
Rename TEMP3.DL TEMP1.DL
ARCE  PLD40.ARC
Rename PLD40.DL TEMP2.DL
CBLD -B CUPL.BLD
Del TEMP1.DL
Del TEMP2.DL
Rename TEMP3.DL TEMP1.DL
ARCE  pld28smt.ARC
Rename pld28smt.DL TEMP2.DL
CBLD -B CUPL.BLD
Del TEMP1.DL
Del TEMP2.DL
Rename TEMP3.DL TEMP1.DL
ARCE  PROMS.ARC
Rename PROMS.DL TEMP2.DL
CBLD -B CUPL.BLD
Del TEMP1.DL
Del TEMP2.DL
Rename TEMP3.DL CUPL.DL
Echo .
Echo .
Echo .
Echo If you want to install the example files, please type:
Echo      ARCE EXAMPLES.ARC
