package app

import (
	"context"

	"github.com/go-kratos/kratos/v2/transport/grpc"
	"github.com/go-kratos/kratos/v2/transport/http"
	"github.com/limes-cloud/kratosx"

	pb "github.com/limes-cloud/manager/api/manager/system/v1"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/service"
	"github.com/limes-cloud/manager/internal/infra/dbs"
	"github.com/limes-cloud/manager/internal/types"
)

type SystemApp struct {
	pb.UnimplementedSystemServer
	srv *service.SystemService
}

func NewSystemApp(conf *conf.Config) *SystemApp {
	return &SystemApp{
		srv: service.NewSystemService(conf, dbs.NewDictionaryInfra()),
	}
}

func init() {
	register(func(c *conf.Config, hs *http.Server, gs *grpc.Server) {
		srv := NewSystemApp(c)
		pb.RegisterSystemHTTPServer(hs, srv)
		pb.RegisterSystemServer(gs, srv)
	})
}

// GetSystemSetting 获取系统设置
func (s *SystemApp) GetSystemSetting(c context.Context, _ *pb.GetSystemSettingRequest) (*pb.GetSystemSettingReply, error) {
	setting := s.srv.GetSystemSetting(kratosx.MustContext(c), &types.GetSystemSettingRequest{})

	reply := pb.GetSystemSettingReply{
		Debug:              setting.Debug,
		Title:              setting.Title,
		Desc:               setting.Desc,
		Copyright:          setting.Copyright,
		Logo:               setting.Logo,
		Watermark:          setting.Watermark,
		ChangePasswordType: setting.ChangePasswordType,
	}
	if len(setting.Dictionaries) != 0 {
		dictArr := make(map[string]*pb.GetSystemSettingReply_DictionaryValueList)
		for _, item := range setting.Dictionaries {
			if dictArr[item.Keyword] == nil {
				dictArr[item.Keyword] = &pb.GetSystemSettingReply_DictionaryValueList{}
			}
			dv := &pb.DictionaryValue{
				Label: item.Label,
				Value: item.Value,
				Type:  item.Type,
				Extra: item.Extra,
			}
			dictArr[item.Keyword].List = append(dictArr[item.Keyword].List, dv)
		}
		reply.Dictionaries = dictArr
	}
	return &reply, nil
}
