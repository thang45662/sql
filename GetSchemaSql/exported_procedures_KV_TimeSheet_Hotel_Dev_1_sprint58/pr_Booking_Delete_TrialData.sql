-- EXEC [pr_Booking_Delete_TrialData] 594151, 23823
ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData]
(
    @tenantId    INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
BEGIN
	-- Xóa ca làm việc
	EXEC [pr_Booking_Delete_TrialData_Shifts] @tenantId, @userId

	-- Xóa nhân viên
	EXEC [pr_Booking_Delete_TrialData_Employees] @tenantId, @userId

	-- Xóa phụ cấp
	EXEC [pr_Booking_Delete_TrialData_Allowance] @tenantId, @userId

	-- Xóa giảm trừ
	EXEC [pr_Booking_Delete_TrialData_Deduction] @tenantId, @userId

	-- Xóa mẫu lương
	EXEC [pr_Booking_Delete_TrialData_PayRateTemplate] @tenantId, @userId

	-- Xóa ca làm việc
	EXEC [pr_Booking_Delete_TrialData_TimeSheet] @tenantId,	@userId

	-- Xóa chấm công
	EXEC [pr_Booking_Delete_TrialData_Clocking] @tenantId, @userId

	-- Xóa bảng lương
	EXEC [pr_Booking_Delete_TrialData_Paysheet] @tenantId, @userId

	-- Xóa phiếu lương
	EXEC [pr_Booking_Delete_TrialData_Payslip] @tenantId, @userId

	--
	EXEC [pr_Booking_Delete_TrialData_PayslipClocking] @tenantId

	SELECT * FROM Employee WHERE TenantId = @tenantId AND IsDeleted = 0 AND UserId != @userId
END

GO
