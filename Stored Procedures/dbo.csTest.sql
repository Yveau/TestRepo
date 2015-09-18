SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[csTest]
--  ----------------------------------------------------------------------------
--  Name            : SQLHeader.sql
--  Date            : 20150917
--  Author          : Ivo Beek - IBEE1
--  Copyright © yyyy, Glencore Grain B.V., All Rights Reserved
--  ----------------------------------------------------------------------------
--  Purpose         : Introduce a standaard header for .sql scripts
--  Parameters      : -
--  Return          : -
--  ----------------------------------------------------------------------------
--  Version    User   Date      change  Comment
--  v00.00.01  IBEE1  20150914          Initial
--  v00.00.02  IBEE1  20150914          Bugfix
--  v00.00.03  IBEE1  20150916          Minor progress
--  v01.00.00  IBEE1  20150917          First major version
--  ----------------------------------------------------------------------------
        @pEen int = 1
AS
BEGIN
        SELECT @pEen
END
GO
