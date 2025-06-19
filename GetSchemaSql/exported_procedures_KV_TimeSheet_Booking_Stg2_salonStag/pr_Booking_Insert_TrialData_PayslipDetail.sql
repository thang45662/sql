----
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayslipDetail]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT,				-- ID tài khoản admin
	@employeeId1 BIGINT,		-- ID nhân viên 1
	@employeeId2 BIGINT,		-- ID nhân viên 2
    @payslipId1 BIGINT,			-- ID phiếu lương 1
    @payslipId2 BIGINT,			-- ID phiếu lương 2
	@allowanceId BIGINT,
	@deductionId BIGINT
)
AS
BEGIN
	DECLARE @numberWorkingDay INT
	SET @numberWorkingDay = DAY(EOMONTH(DATEADD(MONTH, -1, GETDATE())))

	-- Chi tiết phiếu lương 1
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@numberWorkingDay AS VARCHAR(2)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@numberWorkingDay AS VARCHAR(2)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES        (@payslipId1, 'MainSalaryRule', '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":10000000.0,"MainSalaryHolidays":[],"Rank":0}]}', '{"MainSalaryShifts":[{"ShiftId":0,"Salary":10000000.0,"CalculatedSalary":10000000.0,"Default":31.0,"CalculatedDefault":31.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}', @tenantId)

	-- Chi tiết phiếu lương 2
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@numberWorkingDay AS VARCHAR(2)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@numberWorkingDay AS VARCHAR(2)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES        (@payslipId2, 'MainSalaryRule', '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":7000000.0,"MainSalaryHolidays":[],"Rank":0}]}', '{"MainSalaryShifts":[{"ShiftId":0,"Salary":7000000.0,"CalculatedSalary":7000000.0,"Default":31.0,"CalculatedDefault":31.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}', @tenantId)
END

GO
