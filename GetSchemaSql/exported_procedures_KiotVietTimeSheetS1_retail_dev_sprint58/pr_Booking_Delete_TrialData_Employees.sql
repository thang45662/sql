ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Employees]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Employee
	SET                [Code] += '{DEL}', [Name] += '{DEL}', ModifiedBy = @userId, ModifiedDate = GETDATE(), IsDeleted = 1, DeletedBy = @userId, DeletedDate = GETDATE()
	WHERE        (TenantId = @tenantId) AND (IsDeleted = 0) AND (UserId <> @userId OR UserId IS NULL)
END;

GO
