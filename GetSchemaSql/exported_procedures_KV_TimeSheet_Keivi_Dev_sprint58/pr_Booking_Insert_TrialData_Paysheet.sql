ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Paysheet]
(
    @tenantId	INT,			-- ID gian hàng
	@branchId	INT,			-- ID chi nhánh
	@userId	BIGINT,				-- ID tài khoản admin
	@startDate	DATETIME,		-- Ngày bắt đầu
    @language	    NVARCHAR(50),    -- Ngôn ngữ
    @paysheetId BIGINT OUTPUT
)
AS
BEGIN
	DECLARE @paysheetPeriodName VARCHAR(50)
	DECLARE @endDate DATETIME
	SET @endDate = DATEADD(DAY, - 1, DATEADD(MONTH, 1, @startDate))
	SET @paysheetPeriodName = CONVERT(VARCHAR, @startDate, 103) + ' - ' + CONVERT(VARCHAR, @endDate, 103)
	SET @paysheetId = NEXT VALUE FOR PaysheetSeq

    IF (@language = N'en-US')
    BEGIN
        INSERT INTO Paysheet (Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name], SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber, PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay)
	    VALUES (@paysheetId, 'BL000001', @tenantId, @branchId, 0, @userId, GETDATE(), N'General Salary Table ' + @paysheetPeriodName, 1, @startDate, CAST(CONVERT(char(8), @endDate, 112) + ' 23:59:59.000' AS datetime2), 1, '', DATEDIFF(DAY, @startDate, @endDate) + 1, @paysheetPeriodName, @userId, GETDATE(), 0, 0, 8)
    END
    ELSE
    BEGIN
        INSERT INTO Paysheet (Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name], SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber, PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay)
	    VALUES (@paysheetId, 'BL000001', @tenantId, @branchId, 0, @userId, GETDATE(), N'Bảng lương ' + @paysheetPeriodName, 1, @startDate, CAST(CONVERT(char(8), @endDate, 112) + ' 23:59:59.000' AS datetime2), 1, '', DATEDIFF(DAY, @startDate, @endDate) + 1, @paysheetPeriodName, @userId, GETDATE(), 0, 0, 8)
    END
END

GO
