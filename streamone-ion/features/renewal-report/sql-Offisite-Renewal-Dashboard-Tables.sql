CREATE TABLE [dbo].[TABLENAME_SUBS]
(
    [ID]	int IDENTITY(1,1) PRIMARY KEY
	,[importDate]	DATE
    ,[subscriptionId]	NVARCHAR(255)
    ,[subscriptionName]	NVARCHAR(255)
    ,[subscriptionProductId]	NVARCHAR(255)
    ,[subscriptionTotalLicenses]	NVARCHAR(255)
    ,[subscriptionBillingType]	NVARCHAR(255)
    ,[subscriptionBillingCycle]	NVARCHAR(255)
    ,[subscriptionBillingTerm]	NVARCHAR(255)
    ,[subscriptionRenewStatus]	NVARCHAR(255)
    ,[customerPO]	NVARCHAR(255)
    ,[isTrial]	NVARCHAR(255)
    ,[autoRenew]	NVARCHAR(255)
    ,[customerId]	NVARCHAR(255)
    ,[customerName]	NVARCHAR(255)
    ,[partnerName]	NVARCHAR(255)
    ,[lastUpdatedDate]	DATETIME
    ,[price]	NVARCHAR(255)
    ,[cost]	NVARCHAR(255)
    ,[currency]	NVARCHAR(255)
    ,[total]	NVARCHAR(255)
    ,[msrp]	NVARCHAR(255)
    ,[renewalDate]	NVARCHAR(255)
    ,[mfgPartNumber]	NVARCHAR(255)
);

CREATE TABLE [dbo].[TABLENAME_SUBS_HISTORY]
(
    [ID]	int IDENTITY(1,1) PRIMARY KEY
	,[importDate]	DATE
    ,[subscriptionId]	NVARCHAR(255)
    ,[subscriptionName]	NVARCHAR(255)
    ,[subscriptionProductId]	NVARCHAR(255)
    ,[subscriptionTotalLicenses]	NVARCHAR(255)
    ,[subscriptionBillingType]	NVARCHAR(255)
    ,[subscriptionBillingCycle]	NVARCHAR(255)
    ,[subscriptionBillingTerm]	NVARCHAR(255)
    ,[subscriptionRenewStatus]	NVARCHAR(255)
    ,[customerPO]	NVARCHAR(255)
    ,[isTrial]	NVARCHAR(255)
    ,[autoRenew]	NVARCHAR(255)
    ,[customerId]	NVARCHAR(255)
    ,[customerName]	NVARCHAR(255)
    ,[partnerName]	NVARCHAR(255)
    ,[lastUpdatedDate]	DATETIME
    ,[price]	NVARCHAR(255)
    ,[cost]	NVARCHAR(255)
    ,[currency]	NVARCHAR(255)
    ,[total]	NVARCHAR(255)
    ,[msrp]	NVARCHAR(255)
    ,[renewalDate]	NVARCHAR(255)
    ,[mfgPartNumber]	NVARCHAR(255)
);

CREATE TABLE [dbo].[TABLENAME_CUSTOMERS]
(
    [ID]	int IDENTITY(1,1) PRIMARY KEY
    ,[importDate]	DATE
    ,[customerId]	NVARCHAR(255)
    ,[customerName]	NVARCHAR(255)
    ,[contactName]	NVARCHAR(255)
    ,[contactEmail]	NVARCHAR(255)
    ,[contactPhone]	NVARCHAR(255)
    ,[companyStreet]	NVARCHAR(255)
    ,[companyCity]	NVARCHAR(255)
    ,[companyState]	NVARCHAR(255)
    ,[companyZip]	NVARCHAR(255)
    ,[companyCountry]	NVARCHAR(255)
    ,[customFieldsValue]	NVARCHAR(255)

);
