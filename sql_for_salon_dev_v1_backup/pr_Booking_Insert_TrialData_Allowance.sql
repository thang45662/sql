ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Allowance]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT,			-- ID tài khoản admin
    @language	NVARCHAR(50),	-- Ngôn ngữ
	@allowanceId	BIGINT OUTPUT
)
AS
BEGIN
    IF (@language = 'en-US')
    BEGIN
	    SET @allowanceId = NEXT VALUE FOR AllowanceSeq

	    INSERT INTO Allowance (Id, [Name], CreatedBy, CreatedDate, TenantId, Code, IsDeleted, [Value], ValueRatio, [Type], IsChecked, [Rank], test)
	    VALUES        (@allowanceId, N'Food & Beverage', @userId, GETDATE(), @tenantId, 'PC000001', 0, 50000, 0, 1, 1, 0, 0)
    END
    ELSE
    BEGIN
	    SET @allowanceId = NEXT VALUE FOR AllowanceSeq
	    INSERT INTO Allowance (Id, [Name], CreatedBy, CreatedDate, TenantId, Code, IsDeleted, [Value], ValueRatio, [Type], IsChecked, [Rank], test)
	    VALUES        (@allowanceId, N'Ăn uống', @userId, GETDATE(), @tenantId, 'PC000001', 0, 50000, 0, 1, 1, 0, 0)
    END
END

GO
