package types

type AuthRequest struct {
	Path   string `json:"path"`
	Method string `json:"method"`
}
