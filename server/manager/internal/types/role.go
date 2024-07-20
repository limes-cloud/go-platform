package types

type ListRoleRequest struct {
	Name    *string  `json:"name"`
	Keyword *string  `json:"keyword"`
	Ids     []uint32 `json:"ids"`
}
