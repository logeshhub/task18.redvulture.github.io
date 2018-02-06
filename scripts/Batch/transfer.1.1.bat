@ECHO OFF
SETLOCAL

SET _source=\\169.15.14.30\e$\Integration\cafis-level-1

SET _dest=E:\cafis\cafis-level-1

SET _what=/COPY:D
:: /COPYALL :: COPY ALL file info
:: /COPY:D :: copy just the data, exclude attributes and security info
:: /B :: copy files in Backup mode. 
:: /SEC :: copy files with SECurity
:: /MIR :: MIRror a directory tree 

SET _options=/E /R:100 /W:30 /LOG:C:\Temp\transfer.log /TEE /MT:4 /NS /NDL
:: /R:n :: number of Retries
:: /W:n :: Wait time between retries
:: /LOG :: Output log file
:: /NFL :: No file logging
:: /NDL :: No dir logging

ROBOCOPY %_source% %_dest% %_what% %_options%