DECLARE @RC int
EXECUTE @RC = [dbo].[PatientsNotSynced]
EXECUTE @RC = [dbo].[SP_mst_PatientToGreencardRegistration]
GO