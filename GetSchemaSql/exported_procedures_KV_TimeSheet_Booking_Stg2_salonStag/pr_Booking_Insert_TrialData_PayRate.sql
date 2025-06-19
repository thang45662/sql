----
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRate]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT,				-- ID tài khoản admin
	@payRateTemplateId	BIGINT,	-- ID mẫu lương
	@employeeId1	BIGINT,		-- ID nhân viên Hoàng Long
    @employeeId2	BIGINT,		-- ID nhân viên Mai Hương
	@payRateId1 BIGINT OUTPUT,
	@payRateId2 BIGINT OUTPUT
)
AS
BEGIN
	SET @payRateId1 = NEXT VALUE FOR PayRateSeq
	INSERT INTO PayRate (Id, EmployeeId, PayRateTemplateId, TenantId, CreatedDate, CreatedBy, SalaryPeriod)
	VALUES        (@payRateId1, @employeeId1, @payRateTemplateId, @tenantId, GETDATE(), @userId, 1)

	SET @payRateId2 = NEXT VALUE FOR PayRateSeq
	INSERT INTO PayRate (Id, EmployeeId, PayRateTemplateId, TenantId, CreatedDate, CreatedBy, SalaryPeriod)
	VALUES        (@payRateId2, @employeeId2, @payRateTemplateId, @tenantId, GETDATE(), @userId, 1)
END

GO
