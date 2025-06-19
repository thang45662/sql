ALTER PROCEDURE [dbo].[pr_Update_Clocking_Time]
(
@tenantId INT,
@branchId INT,
@shiftId BIGINT,
@shiftFrom BIGINT,
@shiftTo BIGINT,
@returnValue BIGINT OUTPUT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @comparedDate DATETIME2= CONVERT(DATE, DATEADD(day, -30, GETDATE()));
DECLARE @increment INT = 0;
IF @shiftFrom < @shiftTo -- Ca trong ngày
SET @increment = 0
ELSE -- Ca qua đêm
SET @increment = 1
UPDATE dbo.Clocking
SET StartTime = DATEADD(minute, @shiftFrom, CONVERT(DATETIME2, CONVERT(DATE, StartTime))),
EndTime = DATEADD(minute, @shiftTo, CONVERT(DATETIME2, CONVERT(DATE, DATEADD(day, @increment, StartTime))))
WHERE TenantId = @tenantId
AND BranchId = @branchId
AND ShiftId = @shiftId
AND NOT(IsDeleted IS NOT NULL
AND IsDeleted = 1)
AND CheckInDate IS NULL
AND CheckOutDate IS NULL
AND StartTime >= @comparedDate
SET @returnValue = @@ROWCOUNT
END

GO
