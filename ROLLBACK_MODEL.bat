:: Set your old and new date strings here
set "OLD_DATE=202502"
set "NEW_DATE=202503"

@echo off
echo Are you sure to ROLLBACK %NEW_DATE% from %OLD_DATE%？(Y/N)
choice /C YN /M "Proceed?" 
:: 如果使用者選擇 N (No)，ERRORLEVEL 會是 2；因此直接結束腳本
if errorlevel 2 (
    echo 作業已取消。
    goto :EOF
)

:: 依序處理檔名後綴清單 (TA, TB, TC, TD, TE, TF, TG)
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
