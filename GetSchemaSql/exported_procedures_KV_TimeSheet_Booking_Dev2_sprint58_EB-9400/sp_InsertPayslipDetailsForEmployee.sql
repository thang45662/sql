-- Helper stored procedure to reduce code duplication
CREATE   PROCEDURE [dbo].[sp_InsertPayslipDetailsForEmployee]
(
    @payslipId BIGINT,
    @tenantId INT,
    @allowanceTemplate NVARCHAR(MAX),
    @deductionTemplate NVARCHAR(MAX),
    @commissionTemplate NVARCHAR(MAX),
    @mainSalaryAmount DECIMAL(18,2),
    @calculatedDays DECIMAL(5,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert Allowance Rule
    INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
    SELECT TOP 1 @payslipId, RuleType, RuleValue, @allowanceTemplate, @tenantId
    FROM PayRateTemplateDetail
    WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule'
    ORDER BY Id DESC;

    -- Insert Deduction Rule
    INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
    SELECT TOP 1 @payslipId, RuleType, RuleValue, @deductionTemplate, @tenantId
    FROM PayRateTemplateDetail
    WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'
    ORDER BY Id DESC;

    -- Insert Commission Rule
    INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
    SELECT TOP 1 @payslipId, RuleType, RuleValue, @commissionTemplate, @tenantId
    FROM PayRateTemplateDetail
    WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2'
    ORDER BY Id DESC;

    -- Insert Main Salary Rule
    DECLARE @mainSalaryRuleValue NVARCHAR(MAX) =
        '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":' +
        CAST(@mainSalaryAmount AS VARCHAR(20)) +
        ',"MainSalaryHolidays":[],"Rank":0}]}';

    DECLARE @mainSalaryRuleParam NVARCHAR(MAX) =
        '{"MainSalaryShifts":[{"ShiftId":0,"Salary":' +
        CAST(@mainSalaryAmount AS VARCHAR(20)) +
        ',"CalculatedSalary":' + CAST(@mainSalaryAmount AS VARCHAR(20)) +
        ',"Default":31.0,"CalculatedDefault":' + CAST(@calculatedDays AS VARCHAR(10)) +
        ',"MainSalaryByShiftParamDetails":null,"Type":4}]}';

    INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
    VALUES (@payslipId, 'MainSalaryRule', @mainSalaryRuleValue, @mainSalaryRuleParam, @tenantId);
END

GO
