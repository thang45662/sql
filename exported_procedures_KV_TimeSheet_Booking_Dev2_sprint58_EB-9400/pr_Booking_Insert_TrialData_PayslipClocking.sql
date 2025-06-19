ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayslipClocking]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT,				-- ID tài khoản admin
	@employeeId1 BIGINT,		-- ID nhân viên 1
	@employeeId2 BIGINT,		-- ID nhân viên 2
    @payslipId1 BIGINT,			-- ID phiếu lương 1
    @payslipId2 BIGINT			-- ID phiếu lương 2
)
AS
BEGIN
	INSERT INTO PayslipClocking (PayslipId, ClockingId, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, AbsenceType, ClockingStatus, StartTime, EndTime, ShiftId)
	SELECT @payslipId1, Id, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, AbsenceType, ClockingStatus, StartTime, EndTime, ShiftId
	FROM Clocking
	WHERE TenantId = @tenantId AND EmployeeId = @employeeId1

	INSERT INTO PayslipClocking (PayslipId, ClockingId, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, AbsenceType, ClockingStatus, StartTime, EndTime, ShiftId)
	SELECT @payslipId2, Id, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, AbsenceType, ClockingStatus, StartTime, EndTime, ShiftId
	FROM Clocking
	WHERE TenantId = @tenantId AND EmployeeId = @employeeId2
END

GO
