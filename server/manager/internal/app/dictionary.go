package app

import (
	"context"

	"github.com/go-kratos/kratos/v2/transport/grpc"
	"github.com/go-kratos/kratos/v2/transport/http"
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/valx"
	ktypes "github.com/limes-cloud/kratosx/types"

	pb "github.com/limes-cloud/manager/api/manager/dictionary/v1"
	"github.com/limes-cloud/manager/api/manager/errors"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/service"
	"github.com/limes-cloud/manager/internal/infra/dbs"
	"github.com/limes-cloud/manager/internal/types"
)

type DictionaryApp struct {
	pb.UnimplementedDictionaryServer
	srv *service.DictionaryService
}

func NewDictionaryApp(conf *conf.Config) *DictionaryApp {
	return &DictionaryApp{
		srv: service.NewDictionaryService(conf, dbs.NewDictionaryInfra()),
	}
}

func init() {
	register(func(c *conf.Config, hs *http.Server, gs *grpc.Server) {
		srv := NewDictionaryApp(c)
		pb.RegisterDictionaryHTTPServer(hs, srv)
		pb.RegisterDictionaryServer(gs, srv)
	})
}

// GetDictionary 获取指定的字典目录
func (s *DictionaryApp) GetDictionary(c context.Context, req *pb.GetDictionaryRequest) (*pb.GetDictionaryReply, error) {
	result, err := s.srv.GetDictionary(kratosx.MustContext(c), &types.GetDictionaryRequest{
		Id:      req.Id,
		Keyword: req.Keyword,
	})
	if err != nil {
		return nil, err
	}
	return &pb.GetDictionaryReply{
		Id:          result.Id,
		Keyword:     result.Keyword,
		Name:        result.Name,
		Description: result.Description,
		CreatedAt:   uint32(result.CreatedAt),
		UpdatedAt:   uint32(result.UpdatedAt),
	}, nil
}

// ListDictionary 获取字典目录列表
func (s *DictionaryApp) ListDictionary(c context.Context, req *pb.ListDictionaryRequest) (*pb.ListDictionaryReply, error) {
	ctx := kratosx.MustContext(c)
	result, total, err := s.srv.ListDictionary(ctx, &types.ListDictionaryRequest{
		Page:     req.Page,
		PageSize: req.PageSize,
		Keyword:  req.Keyword,
		Name:     req.Name,
	})
	if err != nil {
		return nil, err
	}

	reply := pb.ListDictionaryReply{Total: total}
	if err := valx.Transform(result, &reply.List); err != nil {
		ctx.Logger().Warnw("msg", "reply transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	return &reply, nil
}

// CreateDictionary 创建字典目录
func (s *DictionaryApp) CreateDictionary(c context.Context, req *pb.CreateDictionaryRequest) (*pb.CreateDictionaryReply, error) {
	id, err := s.srv.CreateDictionary(kratosx.MustContext(c), &entity.Dictionary{
		Keyword:     req.Keyword,
		Name:        req.Name,
		Description: req.Description,
	})
	if err != nil {
		return nil, err
	}
	return &pb.CreateDictionaryReply{Id: id}, nil
}

// UpdateDictionary 更新字典目录
func (s *DictionaryApp) UpdateDictionary(c context.Context, req *pb.UpdateDictionaryRequest) (*pb.UpdateDictionaryReply, error) {
	if err := s.srv.UpdateDictionary(kratosx.MustContext(c), &entity.Dictionary{
		BaseModel:   ktypes.BaseModel{Id: req.Id},
		Keyword:     req.Keyword,
		Name:        req.Name,
		Description: req.Description,
	}); err != nil {
		return nil, err
	}

	return &pb.UpdateDictionaryReply{}, nil
}

// DeleteDictionary 删除字典目录
func (s *DictionaryApp) DeleteDictionary(c context.Context, req *pb.DeleteDictionaryRequest) (*pb.DeleteDictionaryReply, error) {
	return &pb.DeleteDictionaryReply{}, s.srv.DeleteDictionary(kratosx.MustContext(c), req.Id)
}

// ListDictionaryValue 获取字典值目录列表
func (s *DictionaryApp) ListDictionaryValue(c context.Context, req *pb.ListDictionaryValueRequest) (*pb.ListDictionaryValueReply, error) {
	ctx := kratosx.MustContext(c)
	result, total, err := s.srv.ListDictionaryValue(ctx, &types.ListDictionaryValueRequest{
		Page:         req.Page,
		PageSize:     req.PageSize,
		DictionaryId: req.DictionaryId,
		Label:        req.Label,
		Value:        req.Value,
		Status:       req.Status,
	})
	if err != nil {
		return nil, err
	}

	reply := pb.ListDictionaryValueReply{Total: total}
	if err := valx.Transform(result, &reply.List); err != nil {
		ctx.Logger().Warnw("msg", "reply transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	return &reply, nil
}

// CreateDictionaryValue 创建字典值目录
func (s *DictionaryApp) CreateDictionaryValue(c context.Context, req *pb.CreateDictionaryValueRequest) (*pb.CreateDictionaryValueReply, error) {
	id, err := s.srv.CreateDictionaryValue(kratosx.MustContext(c), &entity.DictionaryValue{
		DictionaryId: req.DictionaryId,
		Label:        req.Label,
		Value:        req.Value,
		Status:       req.Status,
		Weight:       req.Weight,
		Type:         req.Type,
		Extra:        req.Extra,
		Description:  req.Description,
	})
	if err != nil {
		return nil, err
	}
	return &pb.CreateDictionaryValueReply{Id: id}, nil
}

// UpdateDictionaryValue 更新字典值目录
func (s *DictionaryApp) UpdateDictionaryValue(c context.Context, req *pb.UpdateDictionaryValueRequest) (*pb.UpdateDictionaryValueReply, error) {
	if err := s.srv.UpdateDictionaryValue(kratosx.MustContext(c), &entity.DictionaryValue{
		BaseModel:    ktypes.BaseModel{Id: req.Id},
		DictionaryId: req.DictionaryId,
		Label:        req.Label,
		Value:        req.Value,
		Weight:       req.Weight,
		Type:         req.Type,
		Extra:        req.Extra,
		Description:  req.Description,
	}); err != nil {
		return nil, err
	}

	return &pb.UpdateDictionaryValueReply{}, nil
}

// UpdateDictionaryValueStatus 更新字典值目录状态
func (s *DictionaryApp) UpdateDictionaryValueStatus(c context.Context, req *pb.UpdateDictionaryValueStatusRequest) (*pb.UpdateDictionaryValueStatusReply, error) {
	return &pb.UpdateDictionaryValueStatusReply{}, s.srv.UpdateDictionaryValueStatus(kratosx.MustContext(c), req.Id, req.Status)
}

// DeleteDictionaryValue 删除字典值目录
func (s *DictionaryApp) DeleteDictionaryValue(c context.Context, req *pb.DeleteDictionaryValueRequest) (*pb.DeleteDictionaryValueReply, error) {
	return &pb.DeleteDictionaryValueReply{}, s.srv.DeleteDictionaryValue(kratosx.MustContext(c), req.Id)
}

func (s *DictionaryApp) GetDictionaryValues(c context.Context, req *pb.GetDictionaryValuesRequest) (*pb.GetDictionaryValuesReply, error) {
	var (
		ctx = kratosx.MustContext(c)
	)
	res, err := s.srv.GetDictionaryValues(ctx, req.Keywords)
	if err != nil {
		return nil, err
	}

	reply := pb.GetDictionaryValuesReply{Dict: make(map[string]*pb.GetDictionaryValuesReply_Value)}
	for key, values := range res {
		for _, val := range values {
			reply.Dict[key].List = append(reply.Dict[key].List, &pb.GetDictionaryValuesReply_Value_Item{
				Label:       val.Label,
				Value:       val.Value,
				Type:        val.Type,
				Extra:       val.Extra,
				Description: val.Description,
			})
		}
	}
	return &reply, nil
}
