SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   FUNCTION [dbo].[fnAverageJobDuration]
(       @pJobName sysname
,       @pTop INT
,       @pCalculationMethod CHAR(3)
,       @pIncludeLastJobDuration BIT
)
RETURNS DECIMAL(12,2)
BEGIN
        --DECLARE @lJobName sysname = 'DBAInfo Backup VAT'
        DECLARE @lJobID UNIQUEIDENTIFIER
        DECLARE @lCount INT
        --DECLARE @lTop INT = 10
        DECLARE @lMaxInstanceID INT
        --DECLARE @lCalculation CHAR(3) = 'SMA' -- Simple Moving Average (SMA) | Weighted Moving Average (WMA)
        --DECLARE @lIncludeLastJobDuration BIT = 0
        DECLARE @lAverage DECIMAL(12,2)

        SELECT  @lJobID = job_id
        FROM    msdb.dbo.sysjobs
        WHERE   name = @pJobName;

        SELECT  @lCount = COUNT(1)
        ,       @lMaxInstanceID = MAX(SJH.instance_id) + @pIncludeLastJobDuration
        FROM    msdb.dbo.sysjobhistory SJH
        WHERE   SJH.job_id = @lJobId
        AND     SJH.step_id = 0         --  Only look at total job, not jobsteps
        AND     SJH.run_status = 1;     --  Only look at successful runs

        IF      (@lCount < @pTop)
        BEGIN
                SET     @pTop = @lCount - ~@pIncludeLastJobDuration
        END;

        WITH    Records AS
        (       SELECT  ROW_NUMBER() 
                OVER    (order by run_date, run_time) as 'Row'
        --        ,       SJH.run_duration * 1.0 AS [run_duration] -- in HHMMSS format !! Not seconds !!
                ,       CAST(PARSENAME(STUFF(STUFF(RIGHT('000000' + CAST(SJH.run_duration AS varchar(6)),6),3,0,'.'),6,0,'.'),3) as decimal(10,0))*60.0*60.0
                +       CAST(PARSENAME(STUFF(STUFF(RIGHT('000000' + CAST(SJH.run_duration AS varchar(6)),6),3,0,'.'),6,0,'.'),2) as decimal(10,0))*60.0
                +       CAST(PARSENAME(STUFF(STUFF(RIGHT('000000' + CAST(SJH.run_duration AS varchar(6)),6),3,0,'.'),6,0,'.'),1) as decimal(10,0))*1.0 AS [run_duration]
                FROM    msdb.dbo.sysjobhistory SJH
                WHERE   SJH.job_id = @lJobID
                AND     SJH.step_id = 0
                AND     SJH.run_status = 1
                AND     SJH.instance_id < @lMaxInstanceID
        )
        --SELECT *, Row - @lCount + @lTop + 1 as [weight]
        SELECT  @lAverage = CASE @pCalculationMethod
                        WHEN 'SMA' THEN AVG(Records.run_duration)
                        WHEN 'WMA' THEN SUM((Row - @lCount + @pTop + 1) * Records.run_duration)/(0.5*@pTop*(@pTop+1))
                END
        FROM    Records
        WHERE   Row >= @lCount - @pTop + @pIncludeLastJobDuration;

        --SELECT  @lJobName AS [JobName]
        --,       @lJobID AS [JobID]
        --,       @lCount AS [Count]
        --,       @lTop AS [Top#]
        --,       @lMaxInstanceID AS [MaxInstanceID]
        --,       @lAverage AS [Average];

        RETURN  @lAverage
END







GO
