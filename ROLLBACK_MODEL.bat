:: Set your old and new date strings here
set "OLD_DATE=202502"
set "NEW_DATE=202503"

@echo off
echo Are you sure to ROLLBACK %NEW_DATE% from %OLD_DATE%�H(Y/N)
choice /C YN /M "Proceed?" 
:: �p�G�ϥΪ̿�� N (No)�AERRORLEVEL �|�O 2�F�]�����������}��
if errorlevel 2 (
    echo �@�~�w�����C
    goto :EOF
)

:: �̧ǳB�z�ɦW���M�� (TA, TB, TC, TD, TE, TF, TG)
set "PREFIX=D:\deepmodels\ptmodel\tw\ModelT"
for %%X in (A B C D E F G) do (
    copy /y "%PREFIX%%%X%OLD_DATE%.pt" "%PREFIX%%%X%NEW_DATE%.pt"
    echo "%PREFIX%%%X%OLD_DATE%.pt --> %PREFIX%%%X%NEW_DATE%.pt"
)

set "PREFIX=D:\deepmodels\ptmodel\twn\ModelN"
for %%X in (A B C D E F G) do (
    copy /y "%PREFIX%%%X%OLD_DATE%.pt" "%PREFIX%%%X%NEW_DATE%.pt"
    echo "%PREFIX%%%X%OLD_DATE%.pt --> %PREFIX%%%X%NEW_DATE%.pt"
)

set "PREFIX=D:\deepmodels\pytorch\tw\ModelT"
for %%X in (A B C D E F G) do (
    copy /y "%PREFIX%%%X%OLD_DATE%.mdl" "%PREFIX%%%X%NEW_DATE%.mdl"
    echo "%PREFIX%%%X%OLD_DATE%.mdl --> %PREFIX%%%X%NEW_DATE%.mdl"
)

set "PREFIX=D:\deepmodels\pytorch\twn-30\ModelN"
for %%X in (A B C D E F G) do (
    copy /y "%PREFIX%%%X%OLD_DATE%.mdl" "%PREFIX%%%X%NEW_DATE%.mdl"
    echo "%PREFIX%%%X%OLD_DATE%.mdl --> %PREFIX%%%X%NEW_DATE%.mdl"
)

echo Done copying files!
pause
