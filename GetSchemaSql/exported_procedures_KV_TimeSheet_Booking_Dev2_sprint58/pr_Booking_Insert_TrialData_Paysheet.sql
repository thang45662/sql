-- ========================
-- File: pr_Booking_Insert_TrialData_Paysheet.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Paysheet]
(
    @tenantId	INT,					-- ID gian hàng
	@branchId	INT,					-- ID chi nhánh
	@userId	BIGINT,						-- ID tài khoản admin
	@startDate	DATETIME,				-- Ngày bắt đầu
    @language	    NVARCHAR(50),    	-- Ngôn ngữ
    @paysheetId BIGINT OUTPUT,			-- ID bảng lương tháng hiện tại
    @paysheetIdPrev BIGINT OUTPUT  		-- ID bảng lương tháng trước
)
AS
BEGIN
 ------------------------------------------
    -- 1. Tạo bảng lương tháng trước
    ------------------------------------------

    DECLARE @firstDayPrevMonth DATE, @lastDayPrevMonth DATE;
    IF MONTH(@startDate) = 1
        SET @firstDayPrevMonth = DATEFROMPARTS(YEAR(@startDate) - 1, 12, 1);
    ELSE
    SET @firstDayPrevMonth = DATEFROMPARTS(YEAR(@startDate), MONTH(@startDate) - 1, 1);

    SET @lastDayPrevMonth = EOMONTH(@startDate, -1);

    DECLARE @paysheetPeriodNamePrev NVARCHAR(100);
    SET @paysheetPeriodNamePrev = CONVERT(VARCHAR(10), @firstDayPrevMonth, 103) + ' - ' + CONVERT(VARCHAR(10), @lastDayPrevMonth, 103);
    SET @paysheetIdPrev = NEXT VALUE FOR PaysheetSeq

    IF (@language = N'en-US')
    BEGIN
        INSERT INTO Paysheet (Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name], SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber, PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay)
	    VALUES (@paysheetIdPrev, 'BL000001', @tenantId, @branchId, 0, @userId, GETDATE(), N'General Salary Table ' + @paysheetPeriodNamePrev, 1, @startDate, CAST(CONVERT(char(8), @lastDayPrevMonth, 112) + ' 23:59:59.000' AS datetime2), 1, '', DATEDIFF(DAY, @firstDayPrevMonth, @lastDayPrevMonth) + 1, @paysheetPeriodNamePrev, @userId, GETDATE(), 0, 0, 8)
    END
    ELSE
    BEGIN
        INSERT INTO Paysheet (Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name], SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber, PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay)
	    VALUES (@paysheetIdPrev, 'BL000001', @tenantId, @branchId, 0, @userId, GETDATE(), N'Bảng lương ' + @paysheetPeriodNamePrev, 1, @firstDayPrevMonth, CAST(CONVERT(char(8), @lastDayPrevMonth, 112) + ' 23:59:59.000' AS datetime2), 1, '', DATEDIFF(DAY, @firstDayPrevMonth, @lastDayPrevMonth) + 1, @paysheetPeriodNamePrev, @userId, GETDATE(), 0, 0, 8)
    END

	------------------------------------------
    -- 2. Tạo bảng lương tháng hiện tại (từ ngày hiện tại)
    ------------------------------------------
	DECLARE @currentStartDate DATE = CAST(GETDATE() AS DATE)
	DECLARE @endDate DATETIME = EOMONTH(@currentStartDate)
    DECLARE @workingDayNumber INT
    SET @workingDayNumber = DAY(EOMONTH(GETDATE()))
	DECLARE @paysheetPeriodName VARCHAR(100) = CONVERT(VARCHAR, @currentStartDate, 103) + ' - ' + CONVERT(VARCHAR, @endDate, 103)
	SET @paysheetId = NEXT VALUE FOR PaysheetSeq

    IF (@language = N'en-US')
    BEGIN
        INSERT INTO Paysheet (
            Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name],
            SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber,
            PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay
        )
	    VALUES (
            @paysheetId, 'BL000002', @tenantId, @branchId, 0, @userId, GETDATE(),
            N'General Salary Table ' + @paysheetPeriodName,
            1, @currentStartDate, CAST(CONVERT(char(8), @endDate, 112) + ' 23:59:59.000' AS datetime2),
            1, '', @workingDayNumber, @paysheetPeriodName,
            @userId, GETDATE(), 0, 0, 8
        )
    END
    ELSE
    BEGIN
        INSERT INTO Paysheet (
            Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name],
            SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber,
            PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay
        )
	    VALUES (
            @paysheetId, 'BL000002', @tenantId, @branchId, 0, @userId, GETDATE(),
            N'Bảng lương ' + @paysheetPeriodName,
            1, @currentStartDate, CAST(CONVERT(char(8), @endDate, 112) + ' 23:59:59.000' AS datetime2),
            1, '', @workingDayNumber, @paysheetPeriodName,
            @userId, GETDATE(), 0, 0, 8
        )
    END

END

GO
