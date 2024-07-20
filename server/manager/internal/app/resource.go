package app

import (
	"context"

	"github.com/go-kratos/kratos/v2/transport/grpc"
	"github.com/go-kratos/kratos/v2/transport/http"
	"github.com/limes-cloud/kratosx"

	pb "github.com/limes-cloud/manager/api/manager/resource/v1"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/service"
	"github.com/limes-cloud/manager/internal/infra/dbs"
	"github.com/limes-cloud/manager/internal/types"
)

type ResourceApp struct {
	pb.UnimplementedResourceServer
	srv *service.ResourceService
}

func NewResourceApp(conf *conf.Config) *ResourceApp {
	return &ResourceApp{
		srv: service.NewResourceService(conf, dbs.NewResourceInfra(), dbs.NewDepartmentInfra()),
	}
}

func init() {
	register(func(c *conf.Config, hs *http.Server, gs *grpc.Server) {
		srv := NewResourceApp(c)
		pb.RegisterResourceHTTPServer(hs, srv)
		pb.RegisterResourceServer(gs, srv)
	})
}

// GetResourceScopes 获取当前用户的资源权限
func (r ResourceApp) GetResourceScopes(c context.Context, req *pb.GetResourceScopesRequest) (*pb.GetResourceScopesReply, error) {
	all, ids, err := r.srv.GetResourceScopes(kratosx.MustContext(c), req.Keyword)
	if err != nil {
		return nil, err
	}
	return &pb.GetResourceScopesReply{All: all, Scopes: ids}, nil
}

// GetResource 获取指定用户的资源权限
func (r ResourceApp) GetResource(c context.Context, req *pb.GetResourceRequest) (*pb.GetResourceReply, error) {
	ids, err := r.srv.GetResource(kratosx.MustContext(c), &types.GetResourceRequest{
		Keyword:    req.Keyword,
		ResourceId: req.ResourceId,
	})
	if err != nil {
		return nil, err
	}
	return &pb.GetResourceReply{DepartmentIds: ids}, nil
}

// UpdateResource 更新用户的资源权限
func (r ResourceApp) UpdateResource(c context.Context, req *pb.UpdateResourceRequest) (*pb.UpdateResourceReply, error) {
	if err := r.srv.UpdateResource(kratosx.MustContext(c), &types.UpdateResourceRequest{
		Keyword:       req.Keyword,
		ResourceId:    req.ResourceId,
		DepartmentIds: req.DepartmentIds,
	}); err != nil {
		return nil, err
	}
	return &pb.UpdateResourceReply{}, nil
}
