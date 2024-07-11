+-------------------- FILEEXPORTER: COPYRIGHT NOTICE --------------------+
|                   Copyright (C) Ezra Kenigsberg 2011                   |
| Permission is hereby granted, free of charge, to any person obtaining  |
| a copy of this software and associated documentation files (the        |
| "Software"), to deal in the Software without restriction, including    |
| without limitation the rights to use, copy, modify, merge, publish,    |
| distribute, sublicense, and/or sell copies of the Software, and to     |
| permit persons to whom the Software is furnished to do so, subject to  |
| the following conditions:                                              |
|                                                                        |
| The above copyright notice and this permission notice shall be         |
| included in all copies or substantial portions of the Software.        |
|                                                                        |
| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        |
| EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     |
| MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. |
| IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   |
| CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   |
| TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      |
| SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 |
+------------------------------------------------------------------------+

REQUIREMENTS
1) Windows XP (or above)
2) A Salesforce login with API access
3) Apex Data Loader

HOW TO USE FILEEXPORTER
1) Download the zipfile from http://tinyurl.com/FileExporter
2) Unzip all files from the FileExporter zipfile to a folder on your
   hard drive.
3) Double-click +FileExporter.bat.
4) Respond to onscreen prompts.  Some options are shown in parentheses; do 
   not type parentheses when providing your responses.

FREQUENTLY-ASKED QUESTIONS
Q: "How does FileExporter work?"
A: FileExporter is a command-line utility (ie, a program in a text window) 
   that automates Data Loader.  Neither Salesforce nor Data Loader needs to 
   be open on your PC when you run FileExporter.  Once run, FileExporter 
   will need to know responses to several questions displayed in the text
   window, including username, password, and security token (if required).

Q: "When I run FileExporter, it says 'The system cannot find the path 
   specified.' What does that mean?"
A: FileExporter needs to be told where Data Loader is installed on your PC.
   By default, it assumes "C:\Program Files\salesforce.com\Apex Data Loader 
   21.0".  If you're running Windows 7, Data Loader is more likely 
   installed at "C:\Program Files (x86)\salesforce.com\Apex Data Loader 
   XX.0".  FileExporter's default path can also be customized by editing the
   fourth line of the "+FileExporter.bat" file in Notepad.

Q: "My downloaded Attachments/Content/Documents are empty! What's wrong?"
A: Lately people have been getting heap errors. I've implemented a fix
   (thanks to Sanket Deshmukh!) that helps SOME of the time. Download and 
   use the latest version. If you're still getting zero-byte extracted CSVs
   or empty Attachments/Content/Documents, try one of the following two
   procedures:
   A) export a smaller group of Attachments/Content/Documents; see the last
      Q&A, "Which files does FileExporter download?" below, for examples.
   B) run manual steps to pick up where FileExporter likely crashed:
      1) open a Command Prompt
      2) in the Command Prompt, navigate to the "FileExporter" folder
      3) for Attachments:
           type "cscript Step2a-ReadBody" (without the quotation marks)
         for Content:
           type "cscript Step2cv-ReadBody" (without the quotation marks)
         for Documents:
           type "cscript Step2d-ReadBody" (without the quotation marks)
      4) close the Command Prompt
      5) for Attachments:
           double-click "Step3a-DecryptBody.bat"
         for Content:
           double-click "Step3cv-DecryptBody.bat"
         for Documents:
           double-click "Step3d-DecryptBody.bat"
      6) for Attachments:
           (skip this step)
         for Content:
           double-click "Step4cv-ReplaceFileType.bat"
         for Documents:
           (skip this step)
      7) for Attachments:
           (skip this step)
         for Content:
           double-click "Step5cv-AddFileType.bat"
         for Documents:
           double-click "Step5d-AddType.bat"
      8) for Attachments:
           double-click "Step6a-RenameFile.bat"
         for Content:
           double-click "Step6cv-RenameFile.bat"
         for Documents:
           double-click "Step6d-RenameFile.bat"

Q: "In which folder are the Attachments/Content/Documents downloaded?"
A: By default, the downloaded files are extracted to a subfolder of 
   FileExporter's location, either "Exported Attachments", "Exported
   Content", or "Exported Documents".  The raw CSVs extracted from 
   Salesforce are saved to a subfolder called "CSVs".  Right before 
   quitting, FileExporter offers the option to move the files to another 
   location.

Q: "How fast is FileExporter?"
A: FileExporter's speed depends on the number of documents, the size of the 
   documents, and your internet connection speed.  After downloading data
   from Salesforce, FileExporter needs a few extra moments (usually no more 
   than one minute) to convert the data into distinct files.
   
Q: "Which files does FileExporter download?"
A: FileExporter downloads ALL files of the object type selected (Attachments,
   Content, or Documents).  There is no interface to download specific files.
   HOWEVER, the "beans.xml" configuration file can be modified to download 
   solely the files you want.
   
   Example #1: let's say I only want to download Attachments created on or after 
   Jan 1, 2010.  I need to add "WHERE" clauses to every line in "beans.xml"
   that says "FROM Attachment".  Specifically:
   
   First, I need to change the line that reads
      SELECT Id, Body FROM Attachment ORDER BY Id
   to instead read
      SELECT Id, Body FROM Attachment WHERE CreatedDate>2010-01-01T00:00:00.000Z ORDER BY Id

   Second, I change
      SELECT Id, Name FROM Attachment ORDER BY Id
   to
      SELECT Id, Name FROM Attachment WHERE CreatedDate>2010-01-01T00:00:00.000Z ORDER BY Id

   Third, I change
      SELECT Id, ParentId FROM Attachment ORDER BY Id
   to
      SELECT Id, ParentId FROM Attachment WHERE CreatedDate>2010-01-01T00:00:00.000Z ORDER BY Id

   Example #2: if I only want to extract Accounts' Attachments, I would 
   change the three "WHERE CreatedDate>2010-01-01T00:00:00.000Z" clauses above
   to instead read "WHERE ParentId LIKE '001%'" (without the doublequotes).

   Example #3: if I only want to extract Excel Attachments, I would change 
   the three "WHERE CreatedDate>2010-01-01T00:00:00.000Z" clauses above to 
   instead read "WHERE Name LIKE '%.XLS' OR Name LIKE '%.XLSX'" (without the 
   doublequotes).

   This doesn't cover everything, but hopefully it'll be enough to get you 
   started.  You can try using Data Loader to create SOQL queries via trial 
   and error, too.

CREDITS
   Many thanks to Siftwork's Mike Meyer for his testing and documentation!
   
FEEDBACK
   Questions/bug reports/suggestions?  Email <acumen@gmail.com>.  Thanks!