setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION

:: iterate through all lines of a single CSV
:HandleCSV
	:: call HandleCSVLine for each line (after line #1) in the CSV
	for /f "skip=1 delims=" %%i in (CSVs\Document.Type.csv) do (
		call :HandleCSVLine %%i)
	
::end
endlocal & goto :EOF

:: assign proper extension to each file
:HandleCSVLine
	:: define Id
	set Id=%*
	set Id=%Id:~1,18%
	:: define VersionData
	set Type=%*
	set Type=%Type:~22,-1%
	:: rename file
	ren "Exported Documents\%Id%" "%Id%.%Type%"
	:: rename any files with duplicated extensions
	if exist "Exported Documents\*.%Type%.%Type%" ren "Exported Documents\*.%Type%.%Type%" "*.%Type%"