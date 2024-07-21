package rpcs

import (
	"github.com/limes-cloud/kratosx"
	filev1 "github.com/limes-cloud/resource/api/resource/file/v1"
)

const (
	FileService = "Resource"
)

type FileInfra struct {
}

func NewFileInfra() *FileInfra {
	return &FileInfra{}
}

func (FileInfra) GetFileURL(ctx kratosx.Context, sha string) string {
	conn, err := ctx.GrpcConn(FileService)
	if err != nil {
		ctx.Logger().Warnw("msg", "resource service error", "err", err.Error())
		return ""
	}
	client := filev1.NewFileClient(conn)
	reply, err := client.GetFile(ctx, &filev1.GetFileRequest{Sha: &sha})
	if err != nil {
		ctx.Logger().Warnw("msg", "get resource error", "err", err.Error())
		return ""
	}
	return reply.Url
}
