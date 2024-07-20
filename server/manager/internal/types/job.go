package types

type ListJobRequest struct {
	Page     uint32  `json:"page"`
	PageSize uint32  `json:"pageSize"`
	Keyword  *string `json:"keyword"`
	Name     *string `json:"name"`
}
