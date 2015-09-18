CREATE TABLE [dbo].[RoleMember]
(
[RolePrincipalID] [int] NOT NULL,
[MemberPrincipalID] [int] NOT NULL,
[DatabaseID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[RoleMember] ADD CONSTRAINT [PK_ServerRoleMember] PRIMARY KEY NONCLUSTERED  ([RolePrincipalID], [MemberPrincipalID], [DatabaseID]) ON [PRIMARY]
GO
