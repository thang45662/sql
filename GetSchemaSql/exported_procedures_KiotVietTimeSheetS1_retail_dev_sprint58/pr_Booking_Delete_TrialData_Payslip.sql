ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Payslip]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT				-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Payslip
	SET                PayslipStatus = 0, ModifiedBy = @userId, ModifiedDate = GETDATE()
	WHERE        (TenantId = @tenantId)
END;

GO
