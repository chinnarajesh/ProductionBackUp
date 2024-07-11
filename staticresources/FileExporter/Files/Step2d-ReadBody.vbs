Option Explicit

Main
Wscript.Quit 0

Sub Main()
	'dim variables
	'constants
	Const ForReading = 1
	Const TristateFalse = 0
	Const ChunkSize = 2000000
	'filesystem, file, textstreams
	Dim fs
	Dim filBody
	Dim tsRead
	Dim tsWrite
	'arrays, strings, counter
	Dim arrAll, arrChunk
	Dim strRead, strLine, strId
	Dim lngNum, lngAllCur
	
	'set variables
	Set fs = CreateObject("Scripting.FileSystemObject")
	Set filBody = fs.GetFile("CSVs\Document.Body.csv")
	Set tsRead = filBody.OpenAsTextStream(ForReading, TristateFalse)
	
	'skip first line
	tsRead.SkipLine

	'define the "All Lines" array
	ReDim arrAll(0)
	arrAll(0)=""

	'add arrNextLines to arrAllLines
	Do While Not tsRead.AtEndOfStream
		'populate arrChunk array
		arrChunk = Split(tsRead.Read(ChunkSize), Chr(13) & Chr(10))
		'resize arrAll
		lngAllCur = UBound(arrAll)
		ReDim Preserve arrAll(lngAllCur + UBound(arrChunk))
		For lngNum = 0 To UBound(arrChunk)
			arrAll(lngAllCur + lngNum) = arrAll(lngAllCur + lngNum) & arrChunk(lngNum)
		Next
	Loop

	'create export folder
	On Error Resume Next
	fs.CreateFolder("Exported Documents")
	On Error Goto 0
	'loop
	For lngNum = 0 to UBound(arrAll) - 1
		'update status
		Status("Extracting file #" & lngNum + 1)
		'note that a quotation mark, not a comma, is the delimiter
		strLine = Split(arrAll(lngNum), """")
		If UBound(strLine) >= 3 Then
			strId = strLine(1)
			Set tsWrite = fs.CreateTextFile("Exported Documents\" & strId & ".base64") 
			tsWrite.WriteLine strLine(3)
			tsWrite.Close
		End If
	Next
		
	'clear variables
	Set tsRead = Nothing
	Set tsWrite = Nothing
End Sub

Sub Status (strMessage)
	'If the program was run with CSCRIPT, this writes a
	'line into the DOS box. If run with WSCRIPT, it does nothing.
	Dim ts 'As Scripting.TextStream
	Dim fs 'As Scripting.FileSystemObject
	Const ForAppending = 8 'Scripting.IOMode
	If Lcase(Right(Wscript.FullName, 12)) = "\cscript.exe" Then 
		Wscript.Echo strMessage
	End If
End Sub