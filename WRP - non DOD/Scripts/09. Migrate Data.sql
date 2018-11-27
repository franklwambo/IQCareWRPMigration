IF COL_LENGTH('mst_patient', 'DistrictRegistrationNr') IS NULL
BEGIN
    ALTER TABLE mst_patient
    ADD DistrictRegistrationNr varchar(50)
END

go

DECLARE @RC int
EXECUTE @RC = [dbo].[PatientsNotSynced]
EXECUTE @RC = [dbo].[SP_mst_PatientToGreencardRegistration]
GO
