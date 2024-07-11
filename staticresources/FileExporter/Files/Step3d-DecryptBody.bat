setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION

:: call HandleCSVLine for each line in the CSV
for /f "skip=1" %%i in (CSVs\Document.Name.csv) do (call :HandleCSVLine %%i)

::end
endlocal
goto :EOF

:: decrypt each file and delete encrypted file
:HandleCSVLine
	:: define Id
	set Id=%*
	set Id=%Id:~1,18%
	:: decrypt each file
	base64 -d "Exported Documents\%Id%.base64">"Exported Documents\%Id%"
	del "Exported Documents\%Id%.base64"