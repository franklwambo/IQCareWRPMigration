--USE [IQCare_WRP]
--GO

/****** Object:  StoredProcedure [dbo].[PatientsNotSynced]    Script Date: 11/5/2018 8:44:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author: Felix
-- Create date: 10-Oct-2017
-- Description:	Avoid duplication of patients
-- =============================================
ALTER PROCEDURE [dbo].[PatientsNotSynced]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DECLARE @j INT = 1;
	DECLARE @countj INT;
	--Create Temporary Tables for storing data 
	--CREATE TABLE #Tmst_Patient (Id INT IDENTITY(1,1), ptn_pk int, personId int);

	--INSERT INTO #Tmst_Patient(ptn_pk, personId)
	--SELECT ptn_pk, PersonId FROM Patient
	If Not Exists (Select * From sys.columns Where Name = N'Duplicate' And Object_ID = Object_id(N'Patient')) Begin
		Alter table dbo.Patient Add Duplicate bit 
	End
	DECLARE @ptn_pk int, @personId int, @patientId int, @message varchar(max), @patientmastervisitId int, @rPatientId int;
	
	Insert Into GreenCardBlueCard_Transactional(PersonId,Ptn_Pk)
	Select P.personId
		  ,P.ptn_pk
	From Patient P
	Left Outer Join GreenCardBlueCard_Transactional G On P.personId = G.personId
	Where G.Id Is Null
	And P.DeleteFlag = 0

	DECLARE @d int = 1, @v int = 1;
	DECLARE @countd int, @countv int;

	CREATE TABLE #TPatient(Id INT IDENTITY(1,1), ptn_pk int, personId int, patientId int, OriginalPatientId int);
	CREATE TABLE #TPatientMasterVisit(Id INT IDENTITY(1,1), PatientId int, PatientMasterVisitId int);

	
	Execute( ';With Recs as (
	select P.ptn_Pk, B.Id PatientId, B.PersonId, 
P.MovedToPatientTable,row_number() Over(Partition by B.ptn_pk order by B.Id Asc) RowNum
 from mst_Patient P Inner Join Patient B on P.Ptn_Pk = B.ptn_pk
 ) Update P Set Duplicate = 1 From Patient P Inner Join Recs R On R.PatientId =P.Id Where R.RowNum> 1;

	INSERT INTO #TPatient(ptn_pk, personId, patientId, OriginalPatientId) 
	Select Ptn_Pk , PersonId, P.Id,
	(Select min(X.Id) From Patient X Where X.ptn_pk = P.Ptn_PK And X.Id <> P.Id And x.Duplicate Is Null)
	 from Patient P where P.Duplicate = 1')

	Update V set patientId = tp.OriginalPatientId From #TPatient TP Inner Join PatientMasterVisit V on TP.patientId = V.PatientId 

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].[AdherenceAssessment] A Inner Join #TPatient TP On A.PatientId=TP.patientId
	

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].AdherenceOutcome A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].AdverseEvent A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].ARVTreatmentTracker A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].ComplaintsHistory A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].Disclosure A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].HIVEnrollmentBaseline A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].INHProphylaxis A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientAdverseEventOutcome A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientAllergies A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientAllergy A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientAppointment A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientArtDistribution A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientBaselineAssessment A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientCareending A Inner Join #TPatient TP On A.PatientId=TP.patientId
	
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientCategorization A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientChronicIllness A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientClinicalDiagnosis A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientClinicalNotes A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientConsent A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientDiagnosis A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientEncounter A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientFamilyPlanning A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientFamilyPlanningMethod A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientHivDiagnosis A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientIcf A Inner Join #TPatient TP On A.PatientId=TP.patientId
	
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientIcfAction A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientIpt A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientIptOutcome A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientIptWorkup A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientLabTracker A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientPHDP A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientPhysicalExamination A Inner Join #TPatient TP On A.PatientId=TP.patientId
	
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientProphylaxis A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientPsychosocialCriteria A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientReenrollment A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientReferral A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientScreening A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientSupportSystemCriteria A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientTransferIn A Inner Join #TPatient TP On A.PatientId=TP.patientId
	
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientTreatmentInitiation A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientVitals A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PatientWHOStage A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PhysicalExamination A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].Pregnancy A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PregnancyIndicator A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PregnancyLog A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].PresentingComplaints A Inner Join #TPatient TP On A.PatientId=TP.patientId
	--UPDATE A Set patientId = tp.OriginalPatientId From [dbo].Referrals A Inner Join #TPatient TP On A.PatientId=TP.patientId

	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].Vaccination A Inner Join #TPatient TP On A.PatientId=TP.patientId
	UPDATE A Set patientId = tp.OriginalPatientId From [dbo].TreatmentEventTracker A Inner Join #TPatient TP On A.PatientId=TP.patientId
	
	UPDATE A Set DeleteFlag=1, ptn_pk = - FLOOR(RAND(CHECKSUM(NEWID()))*(9999-1000)+1000) From [dbo].Patient A Inner Join #TPatient TP On A.Id=TP.patientId	
	UPDATE A Set DeleteFlag=1 From [dbo].Person A Inner Join #TPatient TP On A.Id=TP.personId	

	Execute('	If  Exists (Select * From sys.columns Where Name = N''Duplicate'' And Object_ID = Object_id(N''Patient'')) Begin
		Alter table dbo.Patient drop Column Duplicate 
	End')
	
	Execute('IF Not Exists (SELECT * FROM sys.key_constraints WHERE type = ''UQ'' AND parent_object_id = OBJECT_ID(''dbo.Patient'') AND Name = ''unique_ptn_pk'')Begin
	ALTER TABLE Patient	ADD CONSTRAINT unique_ptn_pk UNIQUE (ptn_pk);
End')

	DROP TABLE #TPatient
	DROP TABLE #TPatientMasterVisit
END


GO


