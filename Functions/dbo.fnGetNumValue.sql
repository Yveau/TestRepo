SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[fnGetNumValue] (@pItem varchar(100), @pDatabase sysname) 
returns int
as
begin
		declare @lResult int

		select  @lResult = NumValue
		from	dbo.Parameter
		where   Item = @pItem + ' ' + @pDatabase
		if (@lResult is NULL)
		begin
				select  @lResult = NumValue
				from	dbo.Parameter
				where   Item = 'Default ' + @pItem
		end

		return @lResult
end
GO
