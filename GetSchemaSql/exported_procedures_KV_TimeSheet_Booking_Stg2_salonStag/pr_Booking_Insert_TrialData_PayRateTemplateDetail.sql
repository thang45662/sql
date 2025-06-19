----
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRateTemplateDetail]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT,				-- ID tài khoản admin
	@payRateTemplateId	BIGINT,	-- ID mẫu lương
	@commissionId	BIGINT,		-- ID hoa hồng
    @allowanceId	BIGINT,		-- ID phụ cấp
    @deductionId	BIGINT		-- ID giảm trừ
)
AS
BEGIN
	DECLARE @guid uniqueidentifier
	SET @guid = NEWID()

	INSERT INTO PayRateTemplateDetail (TenantId, PayRateTemplateId, RuleType, RuleValue, CreatedBy, CreatedDate)
	VALUES        (@tenantId, @payRateTemplateId, 'CommissionSalaryRuleV2', '{"Type":1,"FormalityTypes":0,"IsAllBranch":false,"BranchIds":[],"MinCommission":null,"UseMinCommission":false,"CommissionSalaryRuleValueDetails":[{"Group":"' +  CONVERT(NVARCHAR(MAX), @guid) + '","CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '},{"Group":"' +  CONVERT(NVARCHAR(MAX), @guid) + '","CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '}]}', @userId, GETDATE())

	INSERT INTO PayRateTemplateDetail (TenantId, PayRateTemplateId, RuleType, RuleValue, CreatedBy, CreatedDate)
	VALUES        (@tenantId, @payRateTemplateId, 'AllowanceRule', '{"AllowanceRuleValueDetails":[{"AllowanceId":' + CAST(@allowanceId AS VARCHAR(50)) + ',"Name":null,"Value":50000.0,"ValueRatio":null,"Rank":0,"Type":1,"IsChecked":true}]}', @userId, GETDATE())

	INSERT INTO PayRateTemplateDetail (TenantId, PayRateTemplateId, RuleType, RuleValue, CreatedBy, CreatedDate)
	VALUES        (@tenantId, @payRateTemplateId, 'DeductionRule', '{"DeductionRuleValueDetails":[{"DeductionId":' + CAST(@deductionId AS VARCHAR(50)) + ',"Name":null,"Value":10000.0,"ValueRatio":null,"Rank":0,"Type":0,"DeductionRuleId":1,"DeductionTypeId":1,"BlockTypeTimeValue":1,"BlockTypeMinuteValue":10}]}', @userId, GETDATE())
END

GO
