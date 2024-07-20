package app

import (
	"context"

	"github.com/go-kratos/kratos/v2/transport/grpc"
	"github.com/go-kratos/kratos/v2/transport/http"
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/valx"
	ktypes "github.com/limes-cloud/kratosx/types"

	"github.com/limes-cloud/manager/api/manager/errors"
	pb "github.com/limes-cloud/manager/api/manager/job/v1"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/service"
	"github.com/limes-cloud/manager/internal/infra/dbs"
	"github.com/limes-cloud/manager/internal/types"
)

type JobApp struct {
	pb.UnimplementedJobServer
	srv *service.JobService
}

func NewJobApp(conf *conf.Config) *JobApp {
	return &JobApp{
		srv: service.NewJobService(conf, dbs.NewJobInfra()),
	}
}

func init() {
	register(func(c *conf.Config, hs *http.Server, gs *grpc.Server) {
		srv := NewJobApp(c)
		pb.RegisterJobHTTPServer(hs, srv)
		pb.RegisterJobServer(gs, srv)
	})
}

// ListJob 获取职位信息列表
func (s *JobApp) ListJob(c context.Context, req *pb.ListJobRequest) (*pb.ListJobReply, error) {
	var ctx = kratosx.MustContext(c)
	result, total, err := s.srv.ListJob(ctx, &types.ListJobRequest{
		Page:     req.Page,
		PageSize: req.PageSize,
		Keyword:  req.Keyword,
		Name:     req.Name,
	})
	if err != nil {
		return nil, err
	}

	reply := pb.ListJobReply{Total: total}
	if err := valx.Transform(result, &reply.List); err != nil {
		ctx.Logger().Warnw("msg", "reply transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	return &reply, nil
}

// CreateJob 创建职位信息
func (s *JobApp) CreateJob(c context.Context, req *pb.CreateJobRequest) (*pb.CreateJobReply, error) {
	id, err := s.srv.CreateJob(kratosx.MustContext(c), &entity.Job{
		Keyword:     req.Keyword,
		Name:        req.Name,
		Weight:      req.Weight,
		Description: req.Description,
	})
	if err != nil {
		return nil, err
	}

	return &pb.CreateJobReply{Id: id}, nil
}

// UpdateJob 更新职位信息
func (s *JobApp) UpdateJob(c context.Context, req *pb.UpdateJobRequest) (*pb.UpdateJobReply, error) {
	if err := s.srv.UpdateJob(kratosx.MustContext(c), &entity.Job{
		BaseModel:   ktypes.BaseModel{Id: req.Id},
		Keyword:     req.Keyword,
		Name:        req.Name,
		Weight:      req.Weight,
		Description: req.Description,
	}); err != nil {
		return nil, err
	}

	return &pb.UpdateJobReply{}, nil
}

// DeleteJob 删除职位信息
func (s *JobApp) DeleteJob(c context.Context, req *pb.DeleteJobRequest) (*pb.DeleteJobReply, error) {
	return &pb.DeleteJobReply{}, s.srv.DeleteJob(kratosx.MustContext(c), req.Id)
}
