setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION

:: iterate through all lines of a single CSV
:HandleCSV
	:: define first line of new FileType.csv
	echo "ID","FILETYPE">>CSVs\ContentVersion.FileType1.csv
	:: call HandleCSVLine for each line in the CSV
	for /f "skip=1 delims=" %%i in (CSVs\ContentVersion.FileType.csv) do (
		call :HandleCSVLine %%i)
	del CSVs\ContentVersion.FileType.csv
	ren CSVs\ContentVersion.FileType1.csv ContentVersion.FileType.csv
	
::end
endlocal & goto :EOF

:: add CSV line to FileType1.csv
:HandleCSVLine
	:: define Id
	set Id=%*
	set Id=%Id:~1,18%
	:: define VersionData
	set FileType=%*
	set FileType=%FileType:~22,-1%
	if %FileType%==EXCEL_X			set FileType=XLSX
	if %FileType%==EXCEL			set FileType=XLS
	if %FileType%==LINK				set FileType=URL
	if %FileType%==PACK				set FileType=ZIP
	if %FileType%==POWER_POINT_X	set FileType=PPTX
	if %FileType%==POWER_POINT		set FileType=PPT
	if %FileType%==TEXT				set FileType=TXT
	if %FileType%==WORD_X			set FileType=DOCX
	if %FileType%==WORD				set FileType=DOC
	:: add line
	echo "%Id%","%FileType%">>CSVs\ContentVersion.FileType1.csv