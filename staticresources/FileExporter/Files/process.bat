@echo off
:: %1 = Data Loader bin directory
:: %2 = FileExporter directory
:: %3 = process name 
if [%1]==[] goto end
if [%2]==[] goto end
if [%3]==[] goto end

:run
%1\_jvm\bin\java.exe -cp %1\DataLoader.jar -Xms512m -Xmx512m -Dsalesforce.config.dir=%2 com.salesforce.dataloader.process.ProcessRunner process.name=%3

:end
