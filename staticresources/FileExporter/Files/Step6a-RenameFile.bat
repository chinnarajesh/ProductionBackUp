setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION

:: iterate through all lines of a single CSV
:HandleCSV
	:: call HandleCSVLine for each line in the CSV
	for /f "skip=1 delims=" %%i in (CSVs\Attachment.Name.csv) do (
		call :HandleCSVLine %%i)
	
::end
endlocal & goto :EOF

:: rename each file
:HandleCSVLine
	:: define Id
	set Id=%*
	set Id=%Id:~1,18%
	:: define Title. some cute logic is needed to handle ampersands.
	set Name=%*
	set Name=%Name:&=^&%
	set Name=%Name:~22,-1%
	:: rename file
	ren "Exported Attachments\%Id%.*" "%Id%#%Name%.*"