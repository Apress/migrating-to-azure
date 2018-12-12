PRINT 'Creating database sonar...'
CREATE DATABASE sonar
COLLATE SQL_Latin1_General_CP1_CS_AS;
go

PRINT 'Adding user...'
CREATE LOGIN sonar WITH PASSWORD='s0nArqub3',default_Database=sonar
go

PRINT 'Granting permissions...'
EXEC master..sp_addsrvrolemember @loginame = N'sonar', @rolename = N'sysadmin';
go


USE sonar
GO
CREATE USER sonar FROM LOGIN sonar

ALTER ROLE db_owner ADD MEMBER sonar

PRINT 'Operations complete.'
GO

SELECT name FROM sys.databases where name = 'sonar'
GO
