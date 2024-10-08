CREATE TABLE [dbo].[TABLE_STREAMONE_ION_REPORTING_DATA]
(
    [ID]	int IDENTITY(1,1) PRIMARY KEY
	,[date]	       NVARCHAR(20)
    ,[customerName]	       NVARCHAR(MAX)
    ,[customerId]	NVARCHAR(MAX)
    ,[contactName]	NVARCHAR(MAX)
	,[billingMonth]	NVARCHAR(MAX)
    ,[fxRate]	NVARCHAR(MAX)
    ,[cloudType]	NVARCHAR(MAX)
    ,[cloudAccountID]	NVARCHAR(MAX)
    ,[cloudAccountType]	NVARCHAR(MAX)
    ,[resourceGroup]	NVARCHAR(MAX)
    ,[resourceType]	NVARCHAR(MAX)
    ,[category]	       NVARCHAR(MAX)
    ,[cloudUsage]	       NVARCHAR(MAX)
    ,[MWPUsage]	       NVARCHAR(MAX)
    ,[cost]	       NVARCHAR(MAX)
    ,[price]	       NVARCHAR(MAX)
    ,[profit]	       NVARCHAR(MAX)
    ,[markup]	       NVARCHAR(MAX)
    ,[margin]	       NVARCHAR(MAX)
	,[currency]	       NVARCHAR(MAX)
)
