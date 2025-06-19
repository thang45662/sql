ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_TimeSheetShift]
(
@shiftId1 VARCHAR(50),
@shiftId2 VARCHAR(50),
@timeSheetId1 BIGINT,
@timeSheetId2 BIGINT
)
AS
BEGIN
INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds)
VALUES (@timeSheetId1, @shiftId1)

INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds)
VALUES (@timeSheetId2, @shiftId2)
END

GO
