@echo off
echo Test 1: Basic variables
set "TEST_VAR=hello"
echo %TEST_VAR%

echo.
echo Test 2: PORTABLE_DIR
set "PORTABLE_DIR=C:\temp\portable"
echo %PORTABLE_DIR%

echo.
echo Test 3: Simple IF
if "portable" EQU "portable" (
    echo IF works
)

echo.
echo Test 4: Nested IF
if "portable" EQU "portable" (
    echo Outer IF
    if not exist "%PORTABLE_DIR%\test" (
        echo Nested IF works
    )
)

echo.
echo All tests passed!
pause
