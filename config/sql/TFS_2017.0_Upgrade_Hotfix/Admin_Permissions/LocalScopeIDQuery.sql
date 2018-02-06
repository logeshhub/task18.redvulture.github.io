use Tfs_Configuration

select LocalScopeId
from tbl_GroupScope
where PartitionId > 0 and ScopeType = 2 and Active = 1
	and SecuringHostId in (select SecuringHostId from tbl_GroupScope where PartitionId > 0 and Name = 'DevelopmentCollection'
	and ScopeType = 1 and Active = 1)

