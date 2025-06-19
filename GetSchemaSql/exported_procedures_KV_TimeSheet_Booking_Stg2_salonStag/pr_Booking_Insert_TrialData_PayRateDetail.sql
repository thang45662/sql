----
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRateDetail]
(
    @tenantId	INT,			-- ID gian hàng
	@commissionId	BIGINT,		-- ID hoa hồng
    @allowanceId	BIGINT,		-- ID phụ cấp
    @deductionId	BIGINT,		-- ID giảm trừ
	@payRateId1	BIGINT,			-- ID thiết lập lương 1
	@payRateId2	BIGINT,			-- ID thiết lập lương 2
	@employeeId1	BIGINT,		-- ID nhân viên Hoàng Long
    @employeeId2	BIGINT		-- ID nhân viên Mai Hương
)
AS
BEGIN
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId1, 'AllowanceRule', '{"AllowanceRuleValueDetails":[{"AllowanceId":' + CAST(@allowanceId AS VARCHAR(50)) + ',"Name":null,"Value":50000.0,"ValueRatio":null,"Rank":0,"Type":1,"IsChecked":true}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId1, 'CommissionSalaryRuleV2', '{"Type":1,"FormalityTypes":0,"IsAllBranch":false,"BranchIds":[],"MinCommission":null,"UseMinCommission":false,"CommissionSalaryRuleValueDetails":[{"Group":"7172ff88-0668-44c2-81b0-845c582a416b","CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '},{"Group":"7172ff88-0668-44c2-81b0-845c582a416b","CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '}]}', @tenantId)

	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId1, 'DeductionRule', '{"DeductionRuleValueDetails":[{"DeductionId":' + CAST(@deductionId AS VARCHAR(50)) + ',"Name":null,"Value":10000.0,"ValueRatio":null,"Rank":0,"Type":1,"DeductionRuleId":1,"DeductionTypeId":1,"BlockTypeTimeValue":1,"BlockTypeMinuteValue":10}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId1, 'MainSalaryRule', '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":10000000.0,"MainSalaryHolidays":[],"Rank":0}]}', @tenantId)

	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId2, 'AllowanceRule', '{"AllowanceRuleValueDetails":[{"AllowanceId":' + CAST(@allowanceId AS VARCHAR(50)) + ',"Name":null,"Value":50000.0,"ValueRatio":null,"Rank":0,"Type":1,"IsChecked":true}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId2, 'CommissionSalaryRuleV2', '{"Type":1,"FormalityTypes":0,"IsAllBranch":false,"BranchIds":[],"MinCommission":null,"UseMinCommission":false,"CommissionSalaryRuleValueDetails":[{"Group":"7172ff88-0668-44c2-81b0-845c582a416b","CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '},{"Group":"7172ff88-0668-44c2-81b0-845c582a416b","CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId2, 'DeductionRule', '{"DeductionRuleValueDetails":[{"DeductionId":' + CAST(@deductionId AS VARCHAR(50)) + ',"Name":null,"Value":10000.0,"ValueRatio":null,"Rank":0,"Type":0,"DeductionRuleId":1,"DeductionTypeId":1,"BlockTypeTimeValue":1,"BlockTypeMinuteValue":10}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId2, 'MainSalaryRule', '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":7000000.0,"MainSalaryHolidays":[],"Rank":0}]}', @tenantId)
END

GO
