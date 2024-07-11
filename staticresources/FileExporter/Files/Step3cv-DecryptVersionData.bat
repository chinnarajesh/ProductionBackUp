setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION

:: call HandleCSVLine for each line in the CSV
for /f "skip=1" %%i in (CSVs\ContentVersion.FileType.csv) do (call :HandleCSVLine %%i)

::end
endlocal
goto :EOF

:: decrypt each file and delete encrypted file
:HandleCSVLine
	:: define Id
	set Id=%*
	set Id=%Id:~1,18%
	:: decrypt each file
	base64 -d "Exported Content\%Id%.base64">"Exported Content\%Id%"
	del "Exported Content\%Id%.base64"