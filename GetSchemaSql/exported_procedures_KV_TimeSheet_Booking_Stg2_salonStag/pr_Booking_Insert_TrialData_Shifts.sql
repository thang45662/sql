ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Shifts]
(
    @tenantId	INT,		-- ID gian hàng
    @branchId	INT,		-- ID chi nhánh
	@userId		BIGINT,		-- ID tài khoản admin
	@shiftId1	BIGINT OUTPUT,
	@shiftId2	BIGINT OUTPUT
)
AS
BEGIN
	SET @shiftId1 = NEXT VALUE FOR ShiftSeq;
	INSERT INTO [Shift] ([Id], [Name], [From], [To], IsActive, IsDeleted, BranchId, CheckInBefore, CheckOutAfter, TenantId, CreatedBy, CreatedDate)
	VALUES        (@shiftId1, N'Ca sáng', 540, 900, 1, 0, @branchId, 360, 1080, @tenantId, @userId, GETDATE())

	SET @shiftId2 = NEXT VALUE FOR ShiftSeq;
	INSERT INTO [Shift] ([Id], [Name], [From], [To], IsActive, IsDeleted, BranchId, CheckInBefore, CheckOutAfter, TenantId, CreatedBy, CreatedDate)
	VALUES        (@shiftId2, N'Ca chiều - tối', 900, 1350, 1, 0, @branchId, 720, 90, @tenantId, @userId, GETDATE())
END

GO
