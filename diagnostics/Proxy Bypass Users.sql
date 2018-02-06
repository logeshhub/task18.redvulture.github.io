/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [PartitionId]
      ,[CommandId]
      ,[Application]
      ,[Command]
      ,[Status]
      ,(DATEADD(hh,-5,[StartTime])) AS RequestTime
      ,[ExecutionTime]
      ,[IdentityName]
      ,[IPAddress]
      ,[UniqueIdentifier]
      ,[UserAgent]
      ,[CommandIdentifier]
      ,[ExecutionCount]
      ,[TempCorrelationId]
      ,[AuthenticationType]
      ,[AgentId]
      ,[ResponseCode]
      ,[TimeToFirstPage]
      ,[DelayTime]
  FROM [Tfs_DefaultCollection].[dbo].[tbl_Command]
  WHERE Application = 'Version Control'
	AND Command = 'Get'
	AND IPAddress LIKE ('143.122%')
	AND IPAddress NOT IN ('143.122.30.195','143.122.132.196','143.122.132.117','143.122.2.12','169.14.8.133')
	AND UserAgent LIKE ('%devenv.exe%')
	AND IdentityName LIKE ('USAC\%')
	--AND IdentityName = 'USAC\A0N2KZZ'
	AND StartTime > DATEADD(d,-2, GETDATE())
	
ORDER BY RequestTime DESC, IdentityName