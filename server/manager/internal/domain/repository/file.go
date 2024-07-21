package repository

import (
	"github.com/limes-cloud/kratosx"
)

type FileRepository interface {
	GetFileURL(ctx kratosx.Context, sha string) string
}
