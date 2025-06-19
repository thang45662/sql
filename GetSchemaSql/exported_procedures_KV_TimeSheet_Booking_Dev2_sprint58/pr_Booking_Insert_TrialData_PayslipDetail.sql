-- ========================
-- File: pr_Booking_Insert_TrialData_PayslipDetail.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayslipDetail]
(
    @tenantId			INT,
	@userId				BIGINT,
	@employeeId1		BIGINT,
	@employeeId2		BIGINT,
    @payslipId1			BIGINT,
    @payslipId2			BIGINT,
	@payslipIdPrev1		BIGINT,
    @payslipIdPrev2		BIGINT,
	@allowanceId		BIGINT,
	@deductionId		BIGINT,
	@workingDays1		INT,			-- Số ngày công tháng hiện tại nhân viên 1
	@workingDays2		INT,			-- Số ngày công tháng hiện tại nhân viên 2
	@workingDaysPrev1	INT,			-- Số ngày công tháng trước nhân viên 1
	@workingDaysPrev2	INT,			-- Số ngày công tháng trước nhân viên 2
	@shiftId1			BIGINT,
	@shiftId2			BIGINT
)
AS
BEGIN
	-- =====================================================
	-- PHIẾU LƯƠNG THÁNG HIỆN TẠI
	-- =====================================================

	-- Chi tiết phiếu lương tháng hiện tại - Nhân viên 1
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@workingDays1 AS VARCHAR(10)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@workingDays1 AS VARCHAR(10)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES (@payslipId1, 'MainSalaryRule',
		'{"Type":4,"MainSalaryValueDetails":[{"ShiftId":' + CAST(@shiftId1 AS VARCHAR(50)) + ',"Default":10000000.0,"MainSalaryHolidays":[],"Rank":0}]}',
		'{"MainSalaryShifts":[{"ShiftId":' + CAST(@shiftId1 AS VARCHAR(50)) + ',"Salary":10000000.0,"CalculatedSalary":10000000.0,"Default":' + CAST(@workingDays1 AS VARCHAR(10)) + '.0,"CalculatedDefault":' + CAST(@workingDays1 AS VARCHAR(50)) + '.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}',
		@tenantId)

	-- Chi tiết phiếu lương tháng hiện tại - Nhân viên 2
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@workingDays2 AS VARCHAR(10)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@workingDays2 AS VARCHAR(10)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'DeductionRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES (@payslipId2, 'MainSalaryRule',
		'{"Type":4,"MainSalaryValueDetails":[{"ShiftId":' + CAST(@shiftId2 AS VARCHAR(50)) + ',"Default":7000000.0,"MainSalaryHolidays":[],"Rank":0}]}',
		'{"MainSalaryShifts":[{"ShiftId":' + CAST(@shiftId2 AS VARCHAR(50)) + ',"Salary":7000000.0,"CalculatedSalary":7000000.0,"Default":' + CAST(@workingDays2 AS VARCHAR(10)) + '.0,"CalculatedDefault":' + CAST(@workingDays2 AS VARCHAR(50)) + '.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}',
		@tenantId)

	-- =====================================================
	-- PHIẾU LƯƠNG THÁNG TRƯỚC
	-- =====================================================

	-- Chi tiết phiếu lương tháng trước - Nhân viên 1
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev1, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@workingDaysPrev1 AS VARCHAR(10)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@workingDaysPrev1 AS VARCHAR(10)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev1, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev1, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES (@payslipIdPrev1, 'MainSalaryRule',
		'{"Type":4,"MainSalaryValueDetails":[{"ShiftId":' + CAST(@shiftId1 AS VARCHAR(50)) + ',"Default":10000000.0,"MainSalaryHolidays":[],"Rank":0}]}',
		'{"MainSalaryShifts":[{"ShiftId":' + CAST(@shiftId1 AS VARCHAR(50)) + ',"Salary":10000000.0,"CalculatedSalary":10000000.0,"Default":' + CAST(@workingDaysPrev1 AS VARCHAR(10)) + '.0,"CalculatedDefault":' + CAST(@workingDaysPrev1 AS VARCHAR(50)) + '.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}',
		@tenantId)

	-- Chi tiết phiếu lương tháng trước - Nhân viên 2
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev2, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@workingDaysPrev2 AS VARCHAR(10)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@workingDaysPrev2 AS VARCHAR(10)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev2, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'DeductionRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev2, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES (@payslipIdPrev2, 'MainSalaryRule',
		'{"Type":4,"MainSalaryValueDetails":[{"ShiftId":' + CAST(@shiftId2 AS VARCHAR(50)) + ',"Default":7000000.0,"MainSalaryHolidays":[],"Rank":0}]}',
		'{"MainSalaryShifts":[{"ShiftId":' + CAST(@shiftId2 AS VARCHAR(50)) + ',"Salary":7000000.0,"CalculatedSalary":7000000.0,"Default":' + CAST(@workingDaysPrev2 AS VARCHAR(10)) + '.0,"CalculatedDefault":' + CAST(@workingDaysPrev2 AS VARCHAR(50)) + '.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}',
		@tenantId)
END

GO
