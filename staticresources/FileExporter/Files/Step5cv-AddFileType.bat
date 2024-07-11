setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION

:: iterate through all lines of a single CSV
:HandleCSV
	:: call HandleCSVLine for each line (after line #1) in the CSV
	for /f "skip=1 delims=" %%i in (CSVs\ContentVersion.FileType.csv) do (
		call :HandleCSVLine %%i)
	
::end
endlocal & goto :EOF

:: assign proper extension to each file
:HandleCSVLine
	:: define Id
	set Id=%*
	set Id=%Id:~1,18%
	:: define VersionData
	set FileType=%*
	set FileType=%FileType:~22,-1%
	:: rename file
	ren "Exported Content\%Id%" "%Id%.%FileType%"