:PORTABLE_FAIL
echo.
echo ==========================================
echo ERROR: Failed to install Python dependencies
echo ==========================================
echo.
echo The portable Python mode failed to compile TTS library.
echo This typically happens because TTS requires C++ compiler.
echo.
echo SOLUTION: Install full Python 3.10.11 from:
echo https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe
echo.
echo Make sure to check "Add Python to PATH" during installation.
echo Then run this build script again.
echo.
pause
cd "%PROJECT_ROOT%"
exit /b 1
