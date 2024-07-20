package types

type UpdateResourceRequest struct {
	Keyword       string   `json:"keyword"`
	ResourceId    uint32   `json:"resourceId"`
	DepartmentIds []uint32 `json:"departmentIds"`
}

type GetResourceRequest struct {
	Keyword       string   `json:"keyword"`
	ResourceId    uint32   `json:"resourceId"`
	DepartmentIds []uint32 `json:"departmentIds"`
}

type DeleteResourceRequest struct {
	Keyword       string   `json:"keyword"`
	ResourceId    uint32   `json:"resourceId"`
	DepartmentIds []uint32 `json:"departmentIds"`
}

type GetResourceScopesRequest struct {
	Keyword       string   `json:"keyword"`
	DepartmentIds []uint32 `json:"departmentIds"`
}
