package app

import (
	"context"
	"github.com/limes-cloud/manager/internal/infra/rpcs"

	"github.com/go-kratos/kratos/v2/transport/grpc"
	"github.com/go-kratos/kratos/v2/transport/http"
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/valx"
	"google.golang.org/protobuf/types/known/emptypb"

	"github.com/limes-cloud/manager/api/manager/errors"
	pb "github.com/limes-cloud/manager/api/manager/user/v1"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/service"
	"github.com/limes-cloud/manager/internal/infra/dbs"
	"github.com/limes-cloud/manager/internal/types"
)

type UserApp struct {
	pb.UnimplementedUserServer
	srv *service.UseService
}

func NewUserApp(conf *conf.Config) *UserApp {
	return &UserApp{
		srv: service.NewUseService(conf, dbs.NewUserInfra(), dbs.NewDepartmentInfra(), dbs.NewRoleRepo(), rpcs.NewFileInfra()),
	}
}

func init() {
	register(func(c *conf.Config, hs *http.Server, gs *grpc.Server) {
		srv := NewUserApp(c)
		pb.RegisterUserHTTPServer(hs, srv)
		pb.RegisterUserServer(gs, srv)
	})
}

// ListUser 获取用户信息列表
func (s *UserApp) ListUser(c context.Context, req *pb.ListUserRequest) (*pb.ListUserReply, error) {
	var ctx = kratosx.MustContext(c)
	result, total, err := s.srv.ListUser(ctx, &types.ListUserRequest{
		Page:         req.Page,
		PageSize:     req.PageSize,
		Order:        req.Order,
		OrderBy:      req.OrderBy,
		DepartmentId: req.DepartmentId,
		RoleId:       req.RoleId,
		Name:         req.Name,
		Phone:        req.Phone,
		Email:        req.Email,
		Status:       req.Status,
		LoggedAts:    req.LoggedAts,
		CreatedAts:   req.CreatedAts,
	})
	if err != nil {
		return nil, err
	}

	reply := pb.ListUserReply{Total: total}
	if err := valx.Transform(result, &reply.List); err != nil {
		ctx.Logger().Warnw("msg", "reply transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	return &reply, nil
}

// CreateUser 创建用户信息 fixed code
func (s *UserApp) CreateUser(c context.Context, req *pb.CreateUserRequest) (*pb.CreateUserReply, error) {
	var (
		ent = entity.User{}
		ctx = kratosx.MustContext(c)
	)

	if err := valx.Transform(req, &ent); err != nil {
		ctx.Logger().Warnw("msg", "req transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	for _, id := range req.RoleIds {
		ent.UserRoles = append(ent.UserRoles, &entity.UserRole{
			RoleId: id,
		})
	}

	for _, id := range req.JobIds {
		ent.UserJobs = append(ent.UserJobs, &entity.UserJob{
			JobId: id,
		})
	}

	id, err := s.srv.CreateUser(ctx, &ent)
	if err != nil {
		return nil, err
	}

	return &pb.CreateUserReply{Id: id}, nil
}

// UpdateUser 更新用户信息 fixed code
func (s *UserApp) UpdateUser(c context.Context, req *pb.UpdateUserRequest) (*pb.UpdateUserReply, error) {
	var (
		ent = entity.User{}
		ctx = kratosx.MustContext(c)
	)

	if err := valx.Transform(req, &ent); err != nil {
		ctx.Logger().Warnw("msg", "req transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	for _, id := range req.RoleIds {
		ent.UserRoles = append(ent.UserRoles, &entity.UserRole{
			RoleId: id,
		})
	}

	for _, id := range req.JobIds {
		ent.UserJobs = append(ent.UserJobs, &entity.UserJob{
			JobId: id,
		})
	}

	if err := s.srv.UpdateUser(ctx, &ent); err != nil {
		return nil, err
	}

	return &pb.UpdateUserReply{}, nil
}

// DeleteUser 删除用户信息
func (s *UserApp) DeleteUser(c context.Context, req *pb.DeleteUserRequest) (*pb.DeleteUserReply, error) {
	return &pb.DeleteUserReply{}, s.srv.DeleteUser(kratosx.MustContext(c), req.Id)
}

// UpdateUserStatus 更新用户信息状态
func (s *UserApp) UpdateUserStatus(c context.Context, req *pb.UpdateUserStatusRequest) (*pb.UpdateUserStatusReply, error) {
	return &pb.UpdateUserStatusReply{}, s.srv.UpdateUserStatus(kratosx.MustContext(c), req.Id, req.Status)
}

// GetUser 获取指定的用户信息
func (s *UserApp) GetUser(c context.Context, req *pb.GetUserRequest) (*pb.GetUserReply, error) {
	var (
		in  = types.GetUserRequest{}
		ctx = kratosx.MustContext(c)
	)

	if err := valx.Transform(req, &in); err != nil {
		ctx.Logger().Warnw("msg", "request transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	result, err := s.srv.GetUser(ctx, &in)
	if err != nil {
		return nil, err
	}

	reply := pb.GetUserReply{}
	if err := valx.Transform(result, &reply); err != nil {
		ctx.Logger().Warnw("msg", "reply transform err", "err", err.Error())
		return nil, errors.TransformError()
	}
	return &reply, nil
}

func (s *UserApp) GetCurrentUser(c context.Context, _ *emptypb.Empty) (*pb.GetUserReply, error) {
	var (
		ctx = kratosx.MustContext(c)
	)

	result, err := s.srv.GetCurrentUser(ctx)
	if err != nil {
		return nil, err
	}

	reply := pb.GetUserReply{}
	if err = valx.Transform(result, &reply); err != nil {
		ctx.Logger().Warnw("msg", "reply transform err", "err", err.Error())
		return nil, errors.TransformError()
	}
	return &reply, nil
}

func (s *UserApp) ResetUserPassword(c context.Context, req *pb.ResetUserPasswordRequest) (*pb.ResetUserPasswordReply, error) {
	return &pb.ResetUserPasswordReply{}, s.srv.ResetUserPassword(kratosx.MustContext(c), req.Id)
}

func (s *UserApp) UpdateCurrentUser(c context.Context, req *pb.UpdateCurrentUserRequest) (*pb.UpdateCurrentUserReply, error) {
	var (
		in  types.UpdateCurrentUserRequest
		ctx = kratosx.MustContext(c)
	)

	if err := valx.Transform(req, &in); err != nil {
		ctx.Logger().Warnw("msg", "request transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	return &pb.UpdateCurrentUserReply{}, s.srv.UpdateCurrentUser(kratosx.MustContext(c), &in)
}

func (s *UserApp) UpdateCurrentUserRole(c context.Context, req *pb.UpdateCurrentUserRoleRequest) (*pb.UpdateCurrentUserRoleReply, error) {
	return &pb.UpdateCurrentUserRoleReply{}, s.srv.UpdateCurrentUserRole(kratosx.MustContext(c), req.RoleId)
}

func (s *UserApp) UpdateCurrentUserPassword(c context.Context, req *pb.UpdateCurrentUserPasswordRequest) (*pb.UpdateCurrentUserPasswordReply, error) {
	var (
		in  types.UpdateCurrentUserPasswordRequest
		ctx = kratosx.MustContext(c)
	)

	if err := valx.Transform(req, &in); err != nil {
		ctx.Logger().Warnw("msg", "request transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	return &pb.UpdateCurrentUserPasswordReply{}, s.srv.UpdateCurrentUserPassword(ctx, &in)
}

func (s *UserApp) UpdateCurrentUserSetting(c context.Context, req *pb.UpdateCurrentUserSettingRequest) (*pb.UpdateCurrentUserSettingReply, error) {
	return &pb.UpdateCurrentUserSettingReply{}, s.srv.UpdateCurrentUserSetting(kratosx.MustContext(c), req.Setting)
}

func (s *UserApp) UserLogin(c context.Context, req *pb.UserLoginRequest) (*pb.UserLoginReply, error) {
	var (
		in  types.UserLoginRequest
		ctx = kratosx.MustContext(c)
	)

	if err := valx.Transform(req, &in); err != nil {
		ctx.Logger().Warnw("msg", "request transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	token, err := s.srv.UserLogin(ctx, &in)
	if err != nil {
		return nil, err
	}
	return &pb.UserLoginReply{Token: token}, nil
}

func (s *UserApp) UserLogout(c context.Context, _ *emptypb.Empty) (*emptypb.Empty, error) {
	return &emptypb.Empty{}, s.srv.UserLogout(kratosx.MustContext(c))
}

func (s *UserApp) UserRefreshToken(c context.Context, _ *emptypb.Empty) (*pb.UserRefreshTokenReply, error) {
	token, err := s.srv.UserRefreshToken(kratosx.MustContext(c))
	if err != nil {
		return nil, err
	}
	return &pb.UserRefreshTokenReply{Token: token}, nil
}

func (s *UserApp) SendCurrentUserCaptcha(c context.Context, req *pb.SendCurrentUserCaptchaRequest) (*pb.SendCurrentUserCaptchaReply, error) {
	reply, err := s.srv.SendCurrentUserCaptcha(kratosx.MustContext(c), req.Type)
	if err != nil {
		return nil, err
	}
	return &pb.SendCurrentUserCaptchaReply{
		Uuid:    reply.Uuid,
		Captcha: reply.Captcha,
		Expire:  reply.Expire,
	}, nil
}

func (s *UserApp) GetUserLoginCaptcha(c context.Context, _ *emptypb.Empty) (*pb.GetUserLoginCaptchaReply, error) {
	reply, err := s.srv.GetUserLoginCaptcha(kratosx.MustContext(c))
	if err != nil {
		return nil, err
	}
	return &pb.GetUserLoginCaptchaReply{
		Uuid:    reply.Uuid,
		Captcha: reply.Captcha,
		Expire:  reply.Expire,
	}, nil
}
