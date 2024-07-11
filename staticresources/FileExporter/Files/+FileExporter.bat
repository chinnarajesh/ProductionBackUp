@ECHO off

:: set Data Loader Directory
SET DLDir=c:\Program Files\salesforce.com\Apex Data Loader 22.0

:: display disclaimers
CLS
ECHO +-------------------- FILEEXPORTER: COPYRIGHT NOTICE --------------------+
ECHO ^|                   Copyright (C) Ezra Kenigsberg 2011                   ^|
ECHO ^| Permission is hereby granted, free of charge, to any person obtaining  ^|
ECHO ^| a copy of this software and associated documentation files (the        ^|
ECHO ^| "Software"), to deal in the Software without restriction, including    ^|
ECHO ^| without limitation the rights to use, copy, modify, merge, publish,    ^|
ECHO ^| distribute, sublicense, and/or sell copies of the Software, and to     ^|
ECHO ^| permit persons to whom the Software is furnished to do so, subject to  ^|
ECHO ^| the following conditions:                                              ^|
ECHO ^|                                                                        ^|
ECHO ^| The above copyright notice and this permission notice shall be         ^|
ECHO ^| included in all copies or substantial portions of the Software.        ^|
ECHO ^|                                                                        ^|
ECHO ^| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        ^|
ECHO ^| EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     ^|
ECHO ^| MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. ^|
ECHO ^| IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   ^|
ECHO ^| CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   ^|
ECHO ^| TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      ^|
ECHO ^| SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 ^|
ECHO +------------------------------------------------------------------------+

:: write config.properties
ECHO #Loader Config > config.properties

:: create CSVs directory
MD CSVs

:: prompt user for Data Loader directory
ECHO.
ECHO SET DATA LOADER DIRECTORY
ECHO   The default Data Loader location is:
ECHO   "%DLDir%"
SET /P DLDir=  Set Data Loader directory (press enter for default): 

:: store current directory
SET WorkDir=%CD%

:: create process-conf.xml
CALL Step1-GenerateXML.bat "%DLDir%"

:menu
:: show Extract Menu
ECHO.
ECHO MAIN MENU
ECHO   What do you want to do: 
ECHO   (a) Extract Attachments
ECHO   (c) Extract Content
ECHO   (d) Extract Documents
ECHO   (q) Quit

:: prompt user for Main Menu option
ECHO.
SET Option=q
SET /P Option=  Enter your menu option: 
IF %Option%==a GOTO attachments
IF %Option%==c GOTO content
IF %Option%==d GOTO documents
GOTO quit

:attachments
	:: grab Salesforce data
	CALL process.bat "%DLDir%" "%WorkDir%" Attachment.Body
	CALL process.bat "%DLDir%" "%WorkDir%" Attachment.ParentId
	CALL process.bat "%DLDir%" "%WorkDir%" Attachment.Name

	:: pop out to current directory
	POPD

	:: break ExportVersionData.csv into component files
	CALL cscript Step2a-ReadBody.vbs

	:: decrypt component files
	CALL Step3a-DecryptBody.bat

	::skip step 4 (not needed for attachments)

	::skip step 5 (not needed for attachments)

	:: rename component files
	CALL Step6a-RenameFile.bat
	GOTO menu
	
:content
	:: grab Salesforce data
	CALL process.bat "%DLDir%" "%WorkDir%" ContentVersion.FileType
	CALL process.bat "%DLDir%" "%WorkDir%" ContentVersion.FirstPublishLocationId
	CALL process.bat "%DLDir%" "%WorkDir%" ContentVersion.Title
	CALL process.bat "%DLDir%" "%WorkDir%" ContentVersion.VersionData

	:: pop out to current directory
	POPD

	:: break ExportVersionData.csv into component files
	CALL cscript Step2cv-ReadVersionData.vbs

	:: decrypt component files
	CALL Step3cv-DecryptVersionData.bat

	:: replace strings in ExportFileTypes.csv with file extensions
	CALL Step4cv-ReplaceFileType.bat

	:: add file extensions to component files
	CALL Step5cv-AddFileType.bat

	:: rename component files
	CALL Step6cv-RenameFile.bat
	GOTO menu

:documents
	:: grab Salesforce data
	CALL process.bat "%DLDir%" "%WorkDir%" Document.Body
	CALL process.bat "%DLDir%" "%WorkDir%" Document.FolderId
	CALL process.bat "%DLDir%" "%WorkDir%" Document.Name
	CALL process.bat "%DLDir%" "%WorkDir%" Document.Type

	:: pop out to current directory
	POPD

	:: break ExportVersionData.csv into component files
	CALL cscript Step2d-ReadBody.vbs

	:: decrypt component files
	CALL Step3d-DecryptBody.bat

	::skip step 4 (not needed for documents)

	:: add file extensions to component files
	CALL Step5d-AddType.bat

	:: rename component files
	CALL Step6d-RenameFile.bat
	GOTO menu

:quit
:: prompt for target folder
ECHO.
ECHO MOVE EXTRACTED FILES
ECHO   Where should the extracted files be placed? The default file location is:
ECHO   "%WorkDir%"
SET /P WorkDir=  Set target file directory, without quotation marks (press enter for default): 

:: move files to target folder
MD "%WorkDir%\CSVs"
MOVE "CSVs\*.csv" "%WorkDir%\CSVs"
MD "%WorkDir%\Exported Attachments"
MOVE "Exported Attachments\00P*.*" "%WorkDir%\Exported Attachments"
MD "%WorkDir%\Exported Content"
MOVE "Exported Content\068*.*" "%WorkDir%\Exported Content"
MD "%WorkDir%\Exported Documents"
MOVE "Exported Documents\015*.*" "%WorkDir%\Exported Documents"

:: delete working files & folders
RD "CSVs"
RD "Exported Attachments"
RD "Exported Content"
RD "Exported Documents"
DEL Attachment_lastRun.properties
DEL config.properties
DEL Content_lastRun.properties
DEL Document_lastRun.properties
DEL process-conf.xml
