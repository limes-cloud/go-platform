package types

// ListDepartmentRequest fixed code
type ListDepartmentRequest struct {
	Name    *string  `json:"name"`
	Keyword *string  `json:"keyword"`
	Ids     []uint32 `json:"ids"`
}
