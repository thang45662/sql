ALTER PROC [dbo].[pr_GetNextEmployeeCode]
@RetailerId INT = 0
AS
BEGIN

DECLARE @Identity BIGINT = 1;
		DECLARE @MaxCode NVARCHAR(64);

		SELECT TOP 1 @MaxCode = Code
		FROM Employee
		WHERE TenantId = @RetailerId
		AND  Code LIKE N'NV[0-9]%'
		AND SUBSTRING(Code, LEN(N'NV') + 1, LEN(Code)) NOT LIKE N'%[^0-9]%'
		AND LEN(SUBSTRING(Code, LEN('NV') + 1, LEN(Code))) <= 10
		ORDER BY Code DESC

		IF @MaxCode IS NULL
		BEGIN
		    SET @Identity = 1
		END
		ELSE
		BEGIN
			DECLARE @CurrentIdentity NVARCHAR(64)
			SELECT @CurrentIdentity = REPLACE(@MaxCode, 'NV','')
			SELECT @Identity = CAST( @CurrentIdentity AS BIGINT) + 1;
		END

	SELECT @MaxCode as NextCode

END

GO
