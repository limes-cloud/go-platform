package service

import (
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/tree"

	"github.com/limes-cloud/manager/api/manager/errors"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/pkg/md"
	"github.com/limes-cloud/manager/internal/types"
)

type DepartmentService struct {
	conf *conf.Config
	repo repository.DepartmentRepository
}

func NewDepartmentService(config *conf.Config, repo repository.DepartmentRepository) *DepartmentService {
	return &DepartmentService{conf: config, repo: repo}
}

// ListDepartment 获取部门信息列表树
func (u *DepartmentService) ListDepartment(ctx kratosx.Context, req *types.ListDepartmentRequest) ([]tree.Tree, error) {
	// 获取部门列表
	list, err := u.repo.ListDepartment(ctx, req)
	if err != nil {
		ctx.Logger().Warnw("msg", "list department error", "err", err.Error())
		return nil, errors.ListError()
	}

	// 转换为部门树
	var ts []tree.Tree
	for _, item := range list {
		ts = append(ts, item)
	}
	return tree.BuildArrayTree(ts), nil
}

// ListCurrentDepartment 获取当前用户的部门信息列表树
func (u *DepartmentService) ListCurrentDepartment(ctx kratosx.Context, req *types.ListDepartmentRequest) ([]tree.Tree, error) {
	// 获取当前用户的部门权限列表
	all, scopes, err := u.repo.GetDepartmentDataScope(ctx, md.UserId(ctx))
	if err != nil {
		ctx.Logger().Warnw("msg", "list department error", "err", err.Error())
		return nil, errors.DatabaseError()
	}

	// 通过指定权限列表的部门
	if !all {
		req.Ids = scopes
	}
	return u.ListDepartment(ctx, req)
}

// CreateDepartment 创建部门信息
func (u *DepartmentService) CreateDepartment(ctx kratosx.Context, req *entity.Department) (uint32, error) {
	// 是否具有父级部门权限
	hasPurview, err := u.repo.HasDepartmentPurview(ctx, md.UserId(ctx), req.ParentId)
	if err != nil {
		ctx.Logger().Warnw("msg", "get department repo error", "err", err.Error())
		return 0, errors.DatabaseError()
	}

	// 权限判断
	if !hasPurview {
		return 0, errors.DepartmentPurviewError()
	}

	// 更新数据
	id, err := u.repo.CreateDepartment(ctx, req)
	if err != nil {
		return 0, errors.CreateError(err.Error())
	}
	return id, nil
}

// UpdateDepartment 更新部门信息
func (u *DepartmentService) UpdateDepartment(ctx kratosx.Context, req *entity.Department) error {
	if req.Id == 1 {
		return errors.EditSystemDataError()
	}

	// 是否具有父级部门权限
	hasParent, err := u.repo.HasDepartmentPurview(ctx, md.UserId(ctx), req.ParentId)
	if err != nil {
		ctx.Logger().Warnw("msg", "get department repo error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 是否具有当前部门权限
	hasCurrent, err := u.repo.HasDepartmentPurview(ctx, md.UserId(ctx), req.Id)
	if err != nil {
		ctx.Logger().Warnw("msg", "get department repo error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 权限判断
	if !hasParent || !hasCurrent {
		return errors.DepartmentPurviewError()
	}

	// 更新数据
	if err := u.repo.UpdateDepartment(ctx, req); err != nil {
		return errors.UpdateError(err.Error())
	}
	return nil
}

// DeleteDepartment 删除部门信息
func (u *DepartmentService) DeleteDepartment(ctx kratosx.Context, id uint32) error {
	if id == 1 {
		return errors.DeleteSystemDataError()
	}

	// 不能删除当前部门
	if id == md.DepartmentId(ctx) {
		return errors.DepartmentPurviewError()
	}

	// 获取是否具有部门权限
	hasPurview, err := u.repo.HasDepartmentPurview(ctx, md.UserId(ctx), id)
	if err != nil {
		ctx.Logger().Warnw("msg", "get department repo error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 判定权限
	if !hasPurview {
		return errors.DepartmentPurviewError()
	}

	// 更新数据
	if err := u.repo.DeleteDepartment(ctx, id); err != nil {
		return errors.DeleteError(err.Error())
	}
	return nil
}

// GetDepartment 获取指定的部门信息
func (u *DepartmentService) GetDepartment(ctx kratosx.Context, id uint32) (*entity.Department, error) {
	res, err := u.repo.GetDepartment(ctx, id)

	if err != nil {
		return nil, errors.GetError(err.Error())
	}
	return res, nil
}

// GetDepartmentByKeyword 获取指定的部门信息
func (u *DepartmentService) GetDepartmentByKeyword(ctx kratosx.Context, keyword string) (*entity.Department, error) {
	res, err := u.repo.GetDepartmentByKeyword(ctx, keyword)
	if err != nil {
		return nil, errors.GetError(err.Error())
	}
	return res, nil
}
