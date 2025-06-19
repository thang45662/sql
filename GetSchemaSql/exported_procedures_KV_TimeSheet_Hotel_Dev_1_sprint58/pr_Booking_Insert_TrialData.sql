ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData]
(
@tenantId INT, -- ID gian hàng
@branchId INT, -- ID chi nhánh
@userIdAdmin BIGINT, -- ID tài khoản admin
@userId1 BIGINT, -- ID tài khoản nhân viên 1
@userId2 BIGINT, -- ID tài khoản nhân viên 2
@commissionId BIGINT -- ID bảng hoa hồng
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
EXEC [pr_Booking_Insert_TrialData_Shifts] @tenantId, @branchId, @userIdAdmin, @shiftId1 OUTPUT, @shiftId2 OUTPUT

-- Tạo nhân viên
EXEC [pr_Booking_Insert_TrialData_Employees] @tenantId, @branchId, @userIdAdmin, @userId1, @userId2, @employeeId1 OUTPUT, @employeeId2 OUTPUT

-- tạo phụ cấp
EXEC [pr_Booking_Insert_TrialData_Allowance] @tenantId, @userIdAdmin, @allowanceId OUTPUT

-- tạo giảm trừ
EXEC [pr_Booking_Insert_TrialData_Deduction] @tenantId, @userIdAdmin, @deductionId OUTPUT

-- tạo mẫu lương
EXEC [pr_Booking_Insert_TrialData_PayRateTemplate] @tenantId, @branchId, @userIdAdmin, @payRateTemplateId OUTPUT
EXEC [pr_Booking_Insert_TrialData_PayRateTemplateDetail] @tenantId, @userIdAdmin, @payRateTemplateId, @commissionId, @allowanceId, @deductionId

-- tạo thiết lập lương
EXEC [pr_Booking_Insert_TrialData_PayRate] @tenantId, @userIdAdmin, @payRateTemplateId, @employeeId1, @employeeId2, @payRateId1 OUTPUT, @payRateId2 OUTPUT
EXEC [pr_Booking_Insert_TrialData_PayRateDetail] @tenantId, @commissionId, @allowanceId, @deductionId, @payRateId1, @payRateId2, @employeeId1, @employeeId2

-- tạo ca làm việc
DECLARE @startDate DATETIME
DECLARE @endDate DATETIME
SET @startDate = (SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0))
SET @endDate = (SELECT CAST(CONVERT(CHAR(8), GETDATE() - 1, 112) + ' 23:59:59.00' AS datetime))

EXEC [pr_Booking_Insert_TrialData_TimeSheet] @tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @startDate, @endDate, @timeSheetId1 OUTPUT, @timeSheetId2 OUTPUT
EXEC [pr_Booking_Insert_TrialData_TimeSheetShift] @shiftId1 , @shiftId2, @timeSheetId1, @timeSheetId2

-- tạo chấm công
EXEC [pr_Booking_Insert_TrialData_Clocking] @tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @startDate, @endDate, @shiftId1, @shiftId2, @timeSheetId1, @timeSheetId2

-- tạo bảng lương
EXEC [pr_Booking_Insert_TrialData_Paysheet] @tenantId, @branchId, @userIdAdmin, @startDate, @paysheetId OUTPUT

-- tạo phiếu lương
EXEC [pr_Booking_Insert_TrialData_Payslip] @tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @paysheetId, @payslipId1 OUTPUT, @payslipId2 OUTPUT

--
EXEC [pr_Booking_Insert_TrialData_PayslipClocking] @tenantId, @userIdAdmin, @employeeId1, @employeeId2, @payslipId1, @payslipId2

-- tạo chi tiết phiếu lương
EXEC [pr_Booking_Insert_TrialData_PayslipDetail] @tenantId, @userIdAdmin, @employeeId1, @employeeId2, @payslipId1, @payslipId2, @allowanceId, @deductionId

SELECT * FROM Employee WHERE TenantId = @tenantId AND IsDeleted = 0 AND UserId != @userIdAdmin
END


GO
