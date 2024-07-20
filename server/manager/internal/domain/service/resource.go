package service

import (
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/valx"

	"github.com/limes-cloud/manager/api/manager/errors"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/pkg/md"
	"github.com/limes-cloud/manager/internal/types"
)

type ResourceService struct {
	conf *conf.Config
	repo repository.ResourceRepository
	dept repository.DepartmentRepository
}

func NewResourceService(config *conf.Config,
	repo repository.ResourceRepository,
	dept repository.DepartmentRepository,
) *ResourceService {
	return &ResourceService{conf: config, repo: repo, dept: dept}
}

// GetResourceScopes 获取指定的资源权限
func (u *ResourceService) GetResourceScopes(ctx kratosx.Context, keyword string) (bool, []uint32, error) {
	// 获取用户当前的部门权限
	all, scopes, err := u.dept.GetDepartmentDataScope(ctx, md.UserId(ctx))
	if err != nil {
		ctx.Logger().Warnw("msg", "get resource scopes error", "err", err.Error())
		return false, nil, errors.DatabaseError()
	}
	if all {
		return true, nil, nil
	}

	// 获取准许部门的资源列表
	ids, err := u.repo.GetResourceScopes(ctx, &types.GetResourceScopesRequest{
		Keyword:       keyword,
		DepartmentIds: scopes,
	})
	if err != nil {
		return false, nil, err
	}

	return false, ids, nil
}

// GetResource 获取指定的资源权限
func (u *ResourceService) GetResource(ctx kratosx.Context, req *types.GetResourceRequest) ([]uint32, error) {
	// 获取用户当前的部门权限
	all, scopes, err := u.dept.GetDepartmentDataScope(ctx, md.UserId(ctx))
	if err != nil {
		ctx.Logger().Warnw("msg", "get resource scopes error", "err", err.Error())
		return nil, errors.DatabaseError()
	}
	if !all {
		req.DepartmentIds = scopes
	}

	// 获取资源的部门
	ids, err := u.repo.GetResource(ctx, req)
	if err != nil {
		return nil, errors.DatabaseError(err.Error())
	}
	return ids, nil
}

// UpdateResource 更新资源权限
func (u *ResourceService) UpdateResource(ctx kratosx.Context, req *types.UpdateResourceRequest) error {
	// 获取用户当前的部门权限
	all, scopes, err := u.dept.GetDepartmentDataScope(ctx, md.UserId(ctx))
	if err != nil {
		ctx.Logger().Warnw("msg", "get resource scopes error", "err", err.Error())
		return errors.DatabaseError()
	}
	if !all {
		req.DepartmentIds = scopes
	}

	var (
		list []*entity.Resource
		inr  = valx.New(scopes)
	)
	for _, id := range req.DepartmentIds {
		// 过滤管理权限外的部门
		if all || inr.Has(id) {
			list = append(list, &entity.Resource{
				Keyword:      req.Keyword,
				ResourceId:   req.ResourceId,
				DepartmentId: id,
			})
		}
	}

	if err := ctx.Transaction(func(ctx kratosx.Context) error {
		// 删除资源权限
		delReq := &types.DeleteResourceRequest{
			ResourceId: req.ResourceId,
			Keyword:    req.Keyword,
		}
		if !all {
			delReq.DepartmentIds = scopes
		}
		if err := u.repo.DeleteResource(ctx, delReq); err != nil {
			return err
		}

		// 设置新的资源权限
		return u.repo.CreateResources(ctx, list)
	}); err != nil {
		return errors.UpdateError(err.Error())
	}
	return nil
}
