USE [KV_TimeSheet_Booking_Dev2]
GO
/****** Object:  StoredProcedure [dbo].[pr_Booking_Insert_TrialData]    Script Date: 6/13/2025 10:48:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData]
(
    @tenantId			INT,			-- ID gian hàng
	@branchId			INT,			-- ID chi nhánh
	@userIdAdmin		BIGINT,			-- ID tài khoản admin
	@userId1			BIGINT,			-- ID tài khoản nhân viên 1
	@userId2			BIGINT,			-- ID tài khoản nhân viên 2
	@commissionId		BIGINT,			-- ID bảng hoa hồng
	@useNewTimeSheet	BIT,				-- Gian hàng dùng Lịch làm việc 1.0/2.0
	@language			NVARCHAR(50)= N'vi-VN'	-- Ngôn ngữ
)
AS
BEGIN
    SET NOCOUNT ON
	
	DECLARE @shiftId1 BIGINT
	DECLARE @shiftId2 BIGINT
	DECLARE @employeeId1 BIGINT
	DECLARE @employeeId2 BIGINT
	DECLARE @allowanceId BIGINT
	DECLARE @deductionId BIGINT
	DECLARE @payRateTemplateId BIGINT	
	DECLARE @payRateId1 BIGINT
	DECLARE @payRateId2 BIGINT
	DECLARE @timeSheetId1 BIGINT
	DECLARE @timeSheetId2 BIGINT
	DECLARE @paysheetId BIGINT
	DECLARE @payslipId1 BIGINT
	DECLARE @payslipId2 BIGINT
	
	-- Tạo ca làm việc
	EXEC [pr_Booking_Insert_TrialData_Shifts] @tenantId, @branchId, @userIdAdmin, @language, @shiftId1 OUTPUT, @shiftId2 OUTPUT
	
	-- Tạo nhân viên
	EXEC [pr_Booking_Insert_TrialData_Employees] @tenantId, @branchId, @userIdAdmin, @userId1, @userId2, @employeeId1 OUTPUT, @employeeId2 OUTPUT, @language

	-- Tạo bảng hoa hồng

	-- tạo phụ cấp
	EXEC [pr_Booking_Insert_TrialData_Allowance] @tenantId, @userIdAdmin, @language, @allowanceId OUTPUT

	-- tạo phòng ban 
	--EXEC [pr_Booking_Insert_TrialData_Department] @tenantId, @userIdAdmin

	-- tạo chức danh
	--EXEC [pr_Booking_Insert_TrialData_JobTitles] @tenantId, @userIdAdmin

	-- tạo giảm trừ
	EXEC [pr_Booking_Insert_TrialData_Deduction] @tenantId, @userIdAdmin, @language, @deductionId OUTPUT

	-- tạo mẫu lương
	EXEC [pr_Booking_Insert_TrialData_PayRateTemplate] @tenantId, @branchId, @userIdAdmin, @language, @payRateTemplateId OUTPUT
	EXEC [pr_Booking_Insert_TrialData_PayRateTemplateDetail] @tenantId, @userIdAdmin, @payRateTemplateId, @commissionId, @allowanceId, @deductionId

	-- tạo thiết lập lương
	EXEC [pr_Booking_Insert_TrialData_PayRate]  @tenantId, @userIdAdmin, @payRateTemplateId, @employeeId1, @employeeId2, @payRateId1 OUTPUT, @payRateId2 OUTPUT
	EXEC [pr_Booking_Insert_TrialData_PayRateDetail] @tenantId,	@commissionId, @allowanceId, @deductionId, @payRateId1, @payRateId2, @employeeId1, @employeeId2

	-- tạo ca làm việc
	DECLARE @monday DATETIME
	DECLARE @sunday DATETIME
	SET @monday = (SELECT CAST(CONVERT(CHAR(8), DATEADD(dd, 0 - (@@DATEFIRST + 5 + DATEPART(dw, GETDATE())) % 7, GETDATE()), 112) + ' 00:00:00.00' AS datetime))
	SET @sunday = (SELECT CAST(CONVERT(CHAR(8), DATEADD(dd, 6 - (@@DATEFIRST + 5 + DATEPART(dw, GETDATE())) % 7, GETDATE()), 112) + ' 23:59:59.00' AS datetime))

	DECLARE @startDate DATETIME
	DECLARE @endDate DATETIME  
	SET @startDate = (SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0))
	SET @endDate = (SELECT CAST(CONVERT(CHAR(8), GETDATE() - 1, 112) + ' 23:59:59.00' AS datetime))
	
	EXEC [pr_Booking_Insert_TrialData_TimeSheet] @tenantId,	@branchId, @userIdAdmin, @employeeId1, @employeeId2, @startDate, @endDate, @useNewTimeSheet, @monday, @sunday, @timeSheetId1 OUTPUT, @timeSheetId2 OUTPUT
	EXEC [pr_Booking_Insert_TrialData_TimeSheetShift] @shiftId1 , @shiftId2, @timeSheetId1, @timeSheetId2, @useNewTimeSheet
	
	-- tạo chấm công
	EXEC [pr_Booking_Insert_TrialData_Clocking] @tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @startDate, @endDate, @shiftId1, @shiftId2, @timeSheetId1, @timeSheetId2, @useNewTimeSheet, @monday, @sunday

	-- tạo bảng lương
	EXEC [pr_Booking_Insert_TrialData_Paysheet] @tenantId,	@branchId, @userIdAdmin, @startDate, @language,@paysheetId OUTPUT


	-- tạo phiếu lương
	EXEC [pr_Booking_Insert_TrialData_Payslip] @tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @paysheetId, @payslipId1 OUTPUT, @payslipId2 OUTPUT

	--
	EXEC [pr_Booking_Insert_TrialData_PayslipClocking] @tenantId, @userIdAdmin, @employeeId1, @employeeId2, @payslipId1, @payslipId2

	-- tạo chi tiết phiếu lương
	EXEC [pr_Booking_Insert_TrialData_PayslipDetail] @tenantId, @userIdAdmin, @employeeId1, @employeeId2, @payslipId1, @payslipId2, @allowanceId, @deductionId

	SELECT * FROM Employee WHERE TenantId = @tenantId AND IsDeleted = 0 AND UserId != @userIdAdmin

	
END