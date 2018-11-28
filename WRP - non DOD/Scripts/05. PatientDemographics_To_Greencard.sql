--USE [IQCare_WRP]
--GO

/****** Object:  StoredProcedure [dbo].[PatientDemographics_To_Greencard]    Script Date: 11/5/2018 8:47:28 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[PatientDemographics_To_Greencard]
	@ptn_pk int,
	@FirstName varbinary(max),
	@MiddleName varbinary(max),
	@LastName varbinary(max),
	@Sex int,
	@Status_Greencard bit,
	@DeleteFlag bit,
	@CreateDate datetime, 
	@UserID int,
	@PatientFacilityId varchar(50), 
	@PatientType int,
	@FacilityId varchar(10),
	@DateOfBirth datetime, 
	@DobPrecision int, 
	@NationalId varbinary(max),
	@RegistrationDate datetime,
	@PersonId int OUTPUT,
	@PatientId int OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @message varchar(max);

	Insert into Person(FirstName, MidName, LastName, Sex, Active, DeleteFlag, CreateDate, CreatedBy)
	Values(@FirstName, @MiddleName, @LastName, @Sex, @Status_Greencard, @DeleteFlag, @CreateDate, @UserID);

	SET @PersonId = SCOPE_IDENTITY();
	--SET @message = 'Created Person Id: ' + CAST(@PersonId as varchar(50));
	--PRINT @message;

	Insert into Patient(ptn_pk, PersonId, PatientIndex, PatientType, FacilityId, Active, DateOfBirth, DobPrecision, NationalId, DeleteFlag, CreatedBy, CreateDate, RegistrationDate)
	Values(@ptn_pk, @PersonId, @PatientFacilityId, @PatientType, @FacilityId, @Status_Greencard, @DateOfBirth, @DobPrecision, @NationalId, @DeleteFlag, @UserID, @CreateDate, @RegistrationDate);

	SET @PatientId = SCOPE_IDENTITY();
	--SET @message = 'Created Patient Id: ' + CAST(@PatientId as varchar);
	--PRINT @message;

	--SELECT @PersonId, @PatientId;
End

GO


