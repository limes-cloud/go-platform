package app

import (
	"context"

	"github.com/go-kratos/kratos/v2/transport/grpc"
	"github.com/go-kratos/kratos/v2/transport/http"
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/valx"

	"github.com/limes-cloud/manager/api/manager/errors"
	pb "github.com/limes-cloud/manager/api/manager/menu/v1"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/service"
	"github.com/limes-cloud/manager/internal/infra/dbs"
	"github.com/limes-cloud/manager/internal/types"
)

type MenuApp struct {
	pb.UnimplementedMenuServer
	srv *service.MenuService
}

func NewMenuApp(conf *conf.Config) *MenuApp {
	return &MenuApp{
		srv: service.NewMenuService(conf, dbs.NewMenuInfra(), dbs.NewRoleRepo(), dbs.NewRbacInfra()),
	}
}

func init() {
	register(func(c *conf.Config, hs *http.Server, gs *grpc.Server) {
		srv := NewMenuApp(c)
		pb.RegisterMenuHTTPServer(hs, srv)
		pb.RegisterMenuServer(gs, srv)
	})
}

// ListMenu 获取菜单信息列表
func (s *MenuApp) ListMenu(c context.Context, req *pb.ListMenuRequest) (*pb.ListMenuReply, error) {
	var ctx = kratosx.MustContext(c)
	result, err := s.srv.ListMenu(ctx, &types.ListMenuRequest{
		Title: req.Title,
	})
	if err != nil {
		return nil, err
	}

	reply := pb.ListMenuReply{}
	if err := valx.Transform(result, &reply.List); err != nil {
		ctx.Logger().Warnw("msg", "reply transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	return &reply, nil
}

// ListMenuByCurRole 获取当前角色的菜单信息列表
func (s *MenuApp) ListMenuByCurRole(c context.Context, _ *pb.ListMenuByCurRoleRequest) (*pb.ListMenuByCurRoleReply, error) {
	var ctx = kratosx.MustContext(c)
	result, err := s.srv.ListMenuByCurRole(ctx)
	if err != nil {
		return nil, err
	}

	reply := pb.ListMenuByCurRoleReply{}
	if err := valx.Transform(result, &reply.List); err != nil {
		ctx.Logger().Warnw("msg", "reply transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	return &reply, nil
}

// CreateMenu 创建菜单信息
func (s *MenuApp) CreateMenu(c context.Context, req *pb.CreateMenuRequest) (*pb.CreateMenuReply, error) {
	var (
		ctx = kratosx.MustContext(c)
		ent = entity.Menu{}
	)

	if err := valx.Transform(req, &ent); err != nil {
		ctx.Logger().Warnw("msg", "req transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	id, err := s.srv.CreateMenu(ctx, &ent)
	if err != nil {
		return nil, err
	}

	return &pb.CreateMenuReply{Id: id}, nil
}

// UpdateMenu 更新菜单信息
func (s *MenuApp) UpdateMenu(c context.Context, req *pb.UpdateMenuRequest) (*pb.UpdateMenuReply, error) {
	var (
		ctx = kratosx.MustContext(c)
		ent = entity.Menu{}
	)

	if err := valx.Transform(req, &ent); err != nil {
		ctx.Logger().Warnw("msg", "req transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	if err := s.srv.UpdateMenu(ctx, &ent); err != nil {
		return nil, err
	}

	return &pb.UpdateMenuReply{}, nil
}

// DeleteMenu 删除菜单信息
func (s *MenuApp) DeleteMenu(c context.Context, req *pb.DeleteMenuRequest) (*pb.DeleteMenuReply, error) {
	return &pb.DeleteMenuReply{}, s.srv.DeleteMenu(kratosx.MustContext(c), req.Id)
}
