@echo off
setlocal EnableExtensions EnableDelayedExpansion
set SOURCE=C:\source
set DEST=C:\destination
set TEMP=C:\temp

if not exist %SOURCE% Exit /b
if exist %DEST% rmdir %DEST% /s /q
if not exist %TEMP% mkdir %TEMP%
mkdir %DEST%

if exist %DEST%\checksums.txt del %DEST%\checksums.txt

set /a idx=0
for /f "delims=" %%f IN ('dir /b /s "%DEST%\*.*"') DO (
    set /a "idx+=1"
    set "FileName[!idx!]=%%~nxf"
    set "FilePath[!idx!]=%%~dpFf"
    set "tempVar=%%~nxf"
    set bFileName[!idx!]=!tempVar: =!
)

if !idx! equ 0 (echo  no files to zip up) else (set /a checksum=1 
    for /L %%i in (1,1,%idx%) do (

        echo [%%i]  File name = !FileName[%%i]!
        echo [%%i]  bFile name = !bFileName[%%i]!

        set srcFile=%SOURCE%\!FileName[%%i]!
        set dstFile=%DEST%\!FileName[%%i]!

        set bsrcFile=%SOURCE%\!bFileName[%%i]!
        set bdstFile=%DEST%\!bFileName[%%i]!

        rename "!srcFile!" "!bFileName[%%i]!"
        rename "!dstFile!" "!bFileName[%%i]!"

        set /a count=1 
        for /f "skip=1 delims=:" %%a in ('CertUtil -hashfile !bsrcFile! sha256') do (
            if !count! equ 1 set "sha256Src=%%a"
            set/a count+=1
        )
        set sha256Src=!sha256Src: =!
        echo S = !sha256Src!

        set /a count=1 
        for /f "skip=1 delims=:" %%a in ('CertUtil -hashfile !bdstFile! sha256') do (
            if !count! equ 1 set "sha256Dst=%%a"
            set/a count+=1
        )
        set sha256Dst=!sha256Dst: =!
        echo D = !sha256Dst!

        rename "!bsrcFile!" "!FileName[%%i]!"
        rename "!bdstFile!" "!FileName[%%i]!"
        
        echo --------------------------------------------------------------------
        ( 
            echo [%%i]  File name = !FileName[%%i]!
            echo S = !sha256Src!
            echo D = !sha256Dst!
            echo --------------------------------------------------------------------
        )>> %DEST%\checksums.txt
        if !sha256Src! neq !sha256Dst! set/a checksum=0
    )

    if !checksum!==1 (
        echo checksum is ok
        tar -cvf %TEMP%\%dateStr%.zip %DEST%
    )
    if !checksum!==0 (
        echo copy failed : checksums were not the same
        echo copy failed : checksums were not the same>%TEMP%\%dateStr%.txt
    )

    del /q %DEST%\*.*

    if !checksum!==1  (copy %TEMP%\%dateStr%.zip %DEST%\%dateStr%.zip) else (copy %TEMP%\%dateStr%.txt %DEST%\%dateStr%.txt)
)

if exist %TEMP% rmdir %TEMP% /s /q

pause