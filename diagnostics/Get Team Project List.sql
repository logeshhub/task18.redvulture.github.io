use Tfs_Configuration

select LocalScopeId, '"' + REPLACE( REPLACE(Name, '"', '-'), '>', '_') + '"' AS ProjectName
from tbl_GroupScope
where PartitionId > 0
	and ScopeType = 2
	and Active = 1
	and SecuringHostId in (select SecuringHostId from tbl_GroupScope where PartitionId > 0
	and Name = 'DefaultCollection'
	and ScopeType = 1
	and Active = 1)