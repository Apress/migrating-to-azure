USE Benchmarking
GO

create table RunOutput
(
    id INT IDENTITY PRIMARY KEY,
    RunId varchar(50) UNIQUE not NULL,
    RunTime DATETIME not NULL
)

CREATE TABLE RunUrl
(
    UrlId INT IDENTITY PRIMARY KEY,
    Url varchar(2000) NOT NULL,
    Body varchar(3000)
)

CREATE TABLE RunInfo
(
    id INT IDENTITY PRIMARY KEY,
    RunId varchar(50) UNIQUE NOT NULL FOREIGN KEY REFERENCES RunOutput (RunId),
    UrlId INT FOREIGN KEY REFERENCES RunUrl (UrlId)
)

CREATE TABLE RequestInfo
(
    id INT IDENTITY PRIMARY KEY,
    RunInfoId INT FOREIGN KEY REFERENCES RunInfo (id),
    WaitTime INT NOT NULL,
    Seconds INT NOT NULL,
    StartTime VARCHAR(1000),
    CTime INT NOT NULL,
    TTime INT NOT NULL
)