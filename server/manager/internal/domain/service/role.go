package service

import (
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/tree"
	"github.com/limes-cloud/kratosx/pkg/valx"

	"github.com/limes-cloud/manager/api/manager/errors"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/pkg/md"
	"github.com/limes-cloud/manager/internal/types"
)

type RoleService struct {
	conf *conf.Config
	repo repository.RoleRepository
	menu repository.MenuRepository
	rbac repository.RbacRepository
}

func NewRoleService(config *conf.Config,
	repo repository.RoleRepository,
	menu repository.MenuRepository,
	rbac repository.RbacRepository,

) *RoleService {
	return &RoleService{conf: config, repo: repo, menu: menu, rbac: rbac}
}

// GetRole 获取指定的角色信息
func (u *RoleService) GetRole(ctx kratosx.Context, id uint32) (*entity.Role, error) {
	result, err := u.repo.GetRole(ctx, id)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role error", "err", err.Error())
		return nil, errors.GetError()
	}
	return result, nil
}

// GetRoleByKeyword 获取指定的角色信息
func (u *RoleService) GetRoleByKeyword(ctx kratosx.Context, keyword string) (*entity.Role, error) {
	result, err := u.repo.GetRoleByKeyword(ctx, keyword)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role error", "err", err.Error())
		return nil, errors.ListError()
	}
	return result, nil
}

// ListRole 获取角色信息列表树
func (u *RoleService) ListRole(ctx kratosx.Context, req *types.ListRoleRequest) ([]tree.Tree, error) {
	// 获取角色列表
	list, err := u.repo.ListRole(ctx, req)
	if err != nil {
		ctx.Logger().Warnw("msg", "list role error", "err", err.Error())
		return nil, errors.ListError()
	}

	// 转换为角色树
	var ts []tree.Tree
	for _, item := range list {
		ts = append(ts, item)
	}
	return tree.BuildArrayTree(ts), nil
}

// ListCurrentRole 获取当前角色信息列表树
func (u *RoleService) ListCurrentRole(ctx kratosx.Context, req *types.ListRoleRequest) ([]tree.Tree, error) {
	// 获取角色权限
	all, scopes, err := u.repo.GetRoleDataScope(ctx, md.RoleId(ctx))
	if err != nil {
		ctx.Logger().Warnw("msg", "list role error", "err", err.Error())
		return nil, errors.ListError()
	}

	// 通过角色权限构建角色树
	if !all {
		req.Ids = scopes
	}
	return u.ListRole(ctx, req)
}

// CreateRole 创建角色信息 fixed code
func (u *RoleService) CreateRole(ctx kratosx.Context, req *entity.Role) (uint32, error) {
	// 获取是否具有父级角色权限
	hasPurview, err := u.repo.HasRolePurview(ctx, md.UserId(ctx), req.ParentId)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role repo error", "err", err.Error())
		return 0, errors.DatabaseError()
	}

	// 权限判断
	if !hasPurview {
		return 0, errors.RolePurviewError()
	}

	// 创建角色
	id, err := u.repo.CreateRole(ctx, req)
	if err != nil {
		return 0, errors.CreateError(err.Error())
	}
	return id, nil
}

// UpdateRole 更新角色信息 fixed code
func (u *RoleService) UpdateRole(ctx kratosx.Context, req *entity.Role) error {
	// 系统数据不允许修改
	if req.Id == 1 {
		return errors.EditSystemDataError()
	}

	// 获取是否具有父级角色权限
	hasParent, err := u.repo.HasRolePurview(ctx, md.UserId(ctx), req.ParentId)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role repo error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 获取是否具有当前角色权限
	hasCurrent, err := u.repo.HasRolePurview(ctx, md.UserId(ctx), req.Id)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role repo error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 权限判断
	if !hasParent || !hasCurrent {
		return errors.RolePurviewError()
	}

	// 更新角色
	if err := u.repo.UpdateRole(ctx, req); err != nil {
		return err
	}

	return nil
}

// UpdateRoleStatus 更新角色信息状态 fixed code
func (u *RoleService) UpdateRoleStatus(ctx kratosx.Context, id uint32, status bool) error {
	// 系统数据不允许修改
	if id == 1 {
		return errors.EditSystemDataError()
	}

	// 获取是否具有当前角色权限
	hasCurrent, err := u.repo.HasRolePurview(ctx, md.UserId(ctx), id)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role repo error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 权限判定
	if !hasCurrent {
		return errors.RolePurviewError()
	}

	// 更新状态
	if err := u.repo.UpdateRoleStatus(ctx, id, status); err != nil {
		return errors.UpdateError(err.Error())
	}
	return nil
}

// DeleteRole 删除角色信息
func (u *RoleService) DeleteRole(ctx kratosx.Context, id uint32) error {
	if id == 1 {
		return errors.DeleteSystemDataError()
	}

	// 获取是否具有当前角色权限
	hasCurrent, err := u.repo.HasRolePurview(ctx, md.UserId(ctx), id)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role repo error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 权限判定
	if !hasCurrent {
		return errors.RolePurviewError()
	}

	if err := ctx.Transaction(func(ctx kratosx.Context) error {
		// 删除角色
		if err = u.repo.DeleteRole(ctx, id); err != nil {
			return err
		}

		// 删除角色相关权限
		keywords, err := u.repo.GetRoleChildrenKeywords(ctx, id)
		if err != nil {
			return err
		}

		return u.rbac.DeleteRbacRoles(ctx, keywords)
	}); err != nil {
		ctx.Logger().Warnw("msg", "delete role error", "err", err.Error())
		return errors.DeleteError()
	}

	return nil
}

// GetRoleMenuIds 获取指定角色的菜单id列表
func (u *RoleService) GetRoleMenuIds(ctx kratosx.Context, id uint32) ([]uint32, error) {
	// 获取是否具有当前角色权限
	hasCurrent, err := u.repo.HasRolePurview(ctx, md.UserId(ctx), id)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role repo error", "err", err.Error())
		return nil, errors.DatabaseError()
	}

	// 权限判定
	if !hasCurrent {
		return nil, errors.RolePurviewError()
	}

	// 获取菜单id列表
	list, err := u.repo.GetRoleMenuIds(ctx, id)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role menu ids error", "err", err.Error())
		return nil, errors.ListError()
	}
	return list, err
}

// UpdateRoleMenu 更新角色的菜单列表
func (u *RoleService) UpdateRoleMenu(ctx kratosx.Context, roleId uint32, menuIds []uint32) error {
	// 不能更新系统数据
	if roleId == 1 {
		return errors.EditSystemDataError()
	}

	curRoleId := md.RoleId(ctx)

	// 不能更新当前角色
	if roleId == curRoleId {
		return errors.RolePurviewError()
	}

	// 获取是否具有角色权限
	hasCurrent, err := u.repo.HasRolePurview(ctx, curRoleId, roleId)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role repo error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 权限判定
	if !hasCurrent {
		return errors.RolePurviewError()
	}

	// 系统数据时特殊数据，没有菜单，默认获取全部
	if curRoleId != 1 {
		// 获取当前角色的菜单
		curMenuIds, err := u.repo.GetRoleMenuIds(ctx, curRoleId)
		if err != nil {
			ctx.Logger().Warnw("msg", "get role menu ids error", "err", err.Error())
			return errors.DatabaseError()
		}

		// 判断菜单是否越级
		inr := valx.New(curMenuIds)
		for _, id := range menuIds {
			if !inr.Has(id) {
				return errors.MenuPurviewError()
			}
		}
	}

	role, err := u.repo.GetRole(ctx, roleId)
	if err != nil {
		ctx.Logger().Warnw("msg", "get role error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 获取全部菜单api
	apis, err := u.menu.ListMenuApi(ctx)
	if err != nil {
		ctx.Logger().Warnw("msg", "get apis error", "err", err.Error())
		return errors.DatabaseError()
	}

	// 检出当前需要使用的
	var curApis []*types.MenuApi
	inr := valx.New(menuIds)
	for _, api := range apis {
		if inr.Has(api.Id) {
			curApis = append(curApis, api)
		}
	}

	// 更新角色菜单权限
	if err := ctx.Transaction(func(ctx kratosx.Context) error {
		if err := u.rbac.UpdateRbacRoleApis(ctx, role.Keyword, curApis); err != nil {
			return err
		}
		return u.repo.UpdateRoleMenu(ctx, roleId, menuIds)
	}); err != nil {
		return errors.UpdateError(err.Error())
	}

	return nil
}
