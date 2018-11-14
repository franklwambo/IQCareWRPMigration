--USE [IQCare_WRP]
--GO

/****** Object:  StoredProcedure [dbo].[SP_mst_PatientToGreencardRegistration]    Script Date: 11/5/2018 8:46:07 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<felix/stephen>
-- Create date: <03-22-2017>
-- Description:	<Patient registration migration from bluecard to greencard>
-- =============================================
ALTER PROCEDURE [dbo].[SP_mst_PatientToGreencardRegistration]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @ptn_pk int, @FirstName varbinary(max), @MiddleName varbinary(max), @LastName varbinary(max), @Sex int, @Status bit, @Status_Greencard bit , @DeleteFlag bit, @CreateDate datetime, @UserID int,  @message varchar(80), @PersonId int, @PatientFacilityId varchar(50), @PatientType int, @FacilityId varchar(10), @DateOfBirth datetime, @DobPrecision int, @NationalId varbinary(max), @IDNumber varchar(100), @PatientId int, @ARTStartDate date,@transferIn int,@CCCNumber varchar(20), @entryPoint int, @ReferredFrom int, @RegistrationDate datetime, @MaritalStatusId int, @MaritalStatus int, @DistrictName varchar(50), @CountyID int, @SubCountyID int, @WardID int, @Address varbinary(max), @Phone varbinary(max), @EnrollmentId int, @PatientIdentifierId int, @ServiceEntryPointId int, @PatientMaritalStatusID int, @PatientTreatmentSupporterID int, @PersonContactID int, @LocationID int; 
		
	DECLARE @ExitReason int, @ExitDate datetime, @DateOfDeath datetime, @UserID_CareEnded int, @CreateDate_CareEnded datetime;
	
	DECLARE @i INT = 1;
	DECLARE @count INT;
  
	--PRINT '-------- Patients Report --------';  
	exec pr_OpenDecryptedSession;
	
	--Create Temporary Tables for storing data 
	CREATE TABLE #Tmst_Patient(Id INT IDENTITY(1,1), ptn_pk int, FirstName varbinary(max), MiddleName varbinary(max), LastName varbinary(max), Sex int, Status int, DeleteFlag bit, CreateDate datetime, UserID int, PatientFacilityId varchar(50), FacilityId varchar(10), DateOfBirth datetime, DobPrecision int, IDNumber varchar(100), CCCNumber varchar(50), ReferredFrom int, RegistrationDate datetime, MaritalStatus int, DistrictName int, Address varbinary(max), Phone varbinary(max), LocationID int); 

	 --Insert data to temporary table #Tdtl_FamilyInfo 
	INSERT INTO #Tmst_Patient(
		ptn_pk, FirstName, MiddleName, LastName, Sex, Status, DeleteFlag, CreateDate, UserID, PatientFacilityId, FacilityId, DateOfBirth, DobPrecision, IDNumber, CCCNumber, ReferredFrom,
		RegistrationDate, MaritalStatus, DistrictName, Address, Phone, LocationID
	)
	
	SELECT DISTINCT mst_Patient.Ptn_Pk, FirstName, MiddleName ,LastName,Sex, [Status], mst_Patient.DeleteFlag, mst_Patient.CreateDate, mst_Patient.UserID, PatientFacilityId, PosId, DOB, mst_Patient.DobPrecision, [ID/PassportNo], PatientEnrollmentID, [ReferredFrom], mst_Patient.[RegistrationDate], MaritalStatus, DistrictName, Address, Phone, LocationID
	FROM mst_Patient INNER JOIN  dbo.Lnk_PatientProgramStart ON dbo.mst_Patient.Ptn_Pk = dbo.Lnk_PatientProgramStart.Ptn_pk 
	INNER JOIN Patient on  dbo.mst_Patient.Ptn_Pk = dbo.Patient.Ptn_pk
	LEFT JOIN PatientEnrollment on Patient.id=PatientEnrollment.PatientId
	WHERE mst_Patient.DeleteFlag=0
	ORDER BY mst_Patient.Ptn_Pk;

	SELECT @count = COUNT(Id) FROM #Tmst_Patient
	BEGIN
		WHILE (@i <= @count)
			BEGIN
				SELECT @ptn_pk = Ptn_pk, @FirstName = FirstName, @MiddleName = MiddleName, @LastName = LastName, @Sex = Sex, @Status = [Status], @DeleteFlag = DeleteFlag, 
					   @CreateDate = CreateDate, @UserID = UserID, @PatientFacilityId = PatientFacilityId, @FacilityId = FacilityId, @DateOfBirth = DateOfBirth, 
					   @DobPrecision = DobPrecision, @IDNumber = IDNumber, @CCCNumber = CCCNumber, @ReferredFrom = [ReferredFrom], @RegistrationDate = [RegistrationDate], 
					   @MaritalStatus = MaritalStatus, @DistrictName = DistrictName, @Address = Address, @Phone = Phone, @LocationID = LocationID FROM #Tmst_Patient WHERE Id = @i;

				BEGIN TRY
					BEGIN TRANSACTION
						--PRINT ' '  
						--SELECT @message = '----- patients From mst_patient: ' + CAST(@ptn_pk as varchar(50));
						--PRINT @message;

						--set null dates
						IF @CreateDate is null
							SET @CreateDate = getdate()
						--Due to the logic of green card
						IF @Status = 1
							SET @Status_Greencard = 0
						ELSE
							SET @Status_Greencard = 1

						IF @IDNumber IS NULL
							SET @IDNumber = 99999999;

						IF @Sex IS NOT NULL
							BEGIN
								IF ((select top 1  Name from mst_Decode where id = @Sex) = 'Male' OR (select top 1 Name from mst_Decode where id = @Sex) = 'Female')
									BEGIN
										SET @Sex = (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName like '%gender%' and ItemName like + (select top 1  Name from mst_Decode where id = @Sex) + '%');
									END
								ELSE
									SET @Sex = (select top 1  ItemId from LookupItemView where MasterName = 'Unknown' and ItemName = 'Unknown');
							END
						ELSE
							SET @Sex = (select top 1  ItemId from LookupItemView where MasterName = 'Unknown' and ItemName = 'Unknown');

						SET @transferIn=0;
						--Default all persons to new
						SET @ARTStartDate=( SELECT top 1 FORMAT(ARTTransferInDate, 'yyyy-MM-dd') FROM dtl_PatientHivPrevCareIE WHERE Ptn_pk=@ptn_pk And ARTTransferInDate Is Not Null);
						if(@ARTStartDate Is NULL OR @ARTStartDate = '1900-01-01') BEGIN SET @PatientType=(SELECT top 1 Id FROM LookupItem WHERE Name='New');SET @transferIn=0; END ELSE BEGIN SET @PatientType=(SELECT top 1 Id FROM LookupItem WHERE Name='Transfer-In');SET @transferIn=1; END
						-- SELECT @PatientType = 1285

						--encrypt nationalid
						SET @NationalId=ENCRYPTBYKEY(KEY_GUID('Key_CTC'),@IDNumber);
		
						IF @Status = 1
							BEGIN
								DECLARE @PatientExitReason varchar(50);
				
								SET @PatientExitReason = (SELECT TOP 1 Name FROM mst_Decode WHERE CodeID=23 AND ID = (SELECT TOP 1 PatientExitReason FROM dtl_PatientCareEnded WHERE Ptn_Pk = @ptn_pk AND CareEnded=1));
								IF @PatientExitReason = 'Lost to follow-up'
									BEGIN
										SET @PatientExitReason = 'LostToFollowUp';
									END
								ELSE IF @PatientExitReason = 'Transfer to another LPTF' OR @PatientExitReason = 'Transfer to ART'
									BEGIN
										SET @PatientExitReason = 'Transfer Out';
									END
								ELSE IF NOT EXISTS(select top 1 ItemId from LookupItemView where MasterName = 'CareEnded' AND ItemName like '%' + @PatientExitReason + '%')
									BEGIN
										SET @PatientExitReason = 'Transfer Out';
									END
								SET @ExitReason = (select top 1 ItemId from LookupItemView where MasterName = 'CareEnded' AND ItemName like '%' + @PatientExitReason + '%');
								SET @ExitDate = (SELECT top 1 CareEndedDate FROM dtl_PatientCareEnded WHERE Ptn_Pk=@ptn_pk);
								SET @DateOfDeath = (SELECT top 1 DeathDate FROM dtl_PatientCareEnded WHERE Ptn_Pk=@ptn_pk);
								SET @UserID_CareEnded = (SELECT top 1 UserID FROM dtl_PatientCareEnded WHERE Ptn_Pk=@ptn_pk);
								SET @CreateDate_CareEnded = (SELECT top 1 CreateDate FROM dtl_PatientCareEnded WHERE Ptn_Pk=@ptn_pk);
							END

						DECLARE @ModuleId int, @StartDate datetime;

						SET @PatientId = (SELECT top 1 id FROM patient WHERE Ptn_Pk=@ptn_pk);
						
						SET @ModuleId = (	select top 1 ModuleID from mst_module where ModuleName in ('CLINICALCARE','CareandTreatment'))

						SET @PersonId = (SELECT top 1 PersonId FROM patient WHERE Ptn_Pk=@ptn_pk);

						IF NOT EXISTS(SELECT * FROM Patient m WHERE m.id=@PatientId)
							exec [dbo].[PatientDemographics_To_Greencard] @ptn_pk,	@FirstName,	@MiddleName, @LastName,	@Sex, @Status_Greencard, @DeleteFlag, @CreateDate, @UserID, @PatientFacilityId, @PatientType, @FacilityId, @DateOfBirth, @DobPrecision, @NationalId, @RegistrationDate,	@PersonId OUTPUT, @PatientId OUTPUT

						--Insert into Enrollment Table
						IF NOT EXISTS(SELECT * FROM PatientEnrollment m WHERE m.patientid=@PatientId)
							exec [dbo].[PatientEnrollment_To_Greencard] @ptn_pk, @transferIn, @PatientId, @Status, @EnrollmentId OUTPUT, @ModuleId OUTPUT, @StartDate OUTPUT

						--insert into PatientIdentifier, ServiceEntryPoint, MaritalStatus
						exec [dbo].[PatientIdentifiers_To_Greencard] @CCCNumber, @PersonId, @ModuleId, @StartDate, @PatientId, @EnrollmentId, @UserID, @CreateDate,	@ReferredFrom, @entryPoint,	@MaritalStatus,	@MaritalStatusId, @ServiceEntryPointId OUTPUT, @PatientIdentifierId OUTPUT,	@PatientMaritalStatusID OUTPUT

						--Insert into Treatment Supporter
						IF NOT EXISTS(SELECT * FROM PatientTreatmentSupporter m WHERE m.personid=@PersonId)
							exec [dbo].[PatientTreatmentSupporter_To_Greencard] @ptn_pk, @PersonId, @PatientTreatmentSupporterID OUTPUT

						--Insert into Person Contact
						IF NOT EXISTS(SELECT * FROM PersonContact m WHERE m.personid=@PersonId)
							exec [dbo].[PatientContact_To_Greencard] @Address, @Phone, @PersonId, @Status, @UserID, @CreateDate, @PersonContactID OUTPUT

						--Starting baseline
						DECLARE @HBVInfected bit, @Pregnant bit, @TBinfected bit, @WHOStage int, @WHOStageString varchar(50), @BreastFeeding bit, @CD4Count decimal , @MUAC decimal, @Weight decimal, @Height decimal, @artstart datetime, @ClosestARVDate datetime, @PatientMasterVisitId int, @HIVDiagnosisDate datetime, @EnrollmentDate datetime, @EnrollmentWHOStage int, @EnrollmentWHOStageString varchar(50), @VisitDate datetime, @Cohort varchar(50), @visit_id int;
						--if(@ModuleId= 5) Begin	
										
						--exec [dbo].[PatientBaselineVariables_To_Greencard] @ptn_pk, @transferIn, @ARTStartDate, @Sex, @LocationId, @StartDate, @EnrollmentDate OUTPUT, @VisitDate OUTPUT, @artstart OUTPUT, @visit_id OUTPUT, @Pregnant OUTPUT, @HBVInfected OUTPUT, @TBinfected OUTPUT, @WHOStage OUTPUT, @WHOStageString OUTPUT, @BreastFeeding OUTPUT, @CD4Count OUTPUT, @MUAC OUTPUT, @Weight OUTPUT, @Height OUTPUT, @ClosestARVDate OUTPUT, @PatientMasterVisitId OUTPUT, @HIVDiagnosisDate OUTPUT, @EnrollmentWHOStage OUTPUT, @EnrollmentWHOStageString OUTPUT, @Cohort OUTPUT
						--exec [dbo].[PatientBaseline_To_Greencard] @ptn_pk, @PatientId, @EnrollmentDate, @VisitDate, @UserID, @PatientMasterVisitId, @Status, @ExitDate, @CreateDate, @UserID_CareEnded, @CreateDate_CareEnded, @EnrollmentId, @ExitReason, @DateOfDeath, @Weight, @Height, @Pregnant, @TBinfected, @WHOStage, @BreastFeeding,	@CD4Count, @MUAC, @transferIn, @EnrollmentWHOStage,	@HIVDiagnosisDate, @artstart, @Cohort
						
						--End
						--ending baseline
						Update mst_Patient Set MovedToPatientTable =1 Where Ptn_Pk=@ptn_pk;
						INSERT INTO [dbo].[GreenCardBlueCard_Transactional] ([PersonId] ,[Ptn_Pk]) VALUES (@PersonId , @ptn_pk);
						IF @@TRANCOUNT > 0	COMMIT;

						SELECT @message = 'Completed Inserting Patient: ' + CAST(@ptn_pk as varchar);
						PRINT @message;

					END TRY

					BEGIN CATCH
						Declare @ErrorMessage NVARCHAR(4000),@ErrorSeverity Int,@ErrorState Int;

						Select	@ErrorMessage = Error_message(),@ErrorSeverity = Error_severity(),	@ErrorState = Error_state();

						Raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState  );

						IF @@TRANCOUNT > 0  ROLLBACK
					END CATCH

				SELECT @i = @i + 1
			END
		END


		--Now Drop Temporary Tables
		 DROP TABLE #Tmst_Patient
		 
		 exec [dbo].[pr_CloseDecryptedSession];
END

GO


