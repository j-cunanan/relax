if not exist output2 mkdir output2


set OMP_NUM_THREADS=4

set GMT_SHAREDIR=%CD%\..\..\share
set PROJ_LIB=%CD%\..\..\share
..\..\relax --no-proj-output < run2.input
PAUSE
