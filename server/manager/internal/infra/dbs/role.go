package dbs

import (
	"errors"
	"sync"

	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/valx"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/types"
)

type RoleInfra struct {
}

var (
	_RoleInfra     *RoleInfra
	_RoleInfraOnce sync.Once
)

func NewRoleRepo() repository.RoleRepository {
	_RoleInfraOnce.Do(func() {
		_RoleInfra = &RoleInfra{}
	})
	return _RoleInfra
}

// GetRole 获取指定的数据
func (r *RoleInfra) GetRole(ctx kratosx.Context, id uint32) (*entity.Role, error) {
	var role = entity.Role{}
	return &role, ctx.DB().First(&role, id).Error
}

// GetRoleByKeyword 获取指定数据
func (r *RoleInfra) GetRoleByKeyword(ctx kratosx.Context, keyword string) (*entity.Role, error) {
	var role = entity.Role{}
	return &role, ctx.DB().Where("keyword = ?", keyword).First(&role).Error
}

// ListRole 获取列表
func (r *RoleInfra) ListRole(ctx kratosx.Context, req *types.ListRoleRequest) ([]*entity.Role, error) {
	var (
		es []*entity.Role
		fs = []string{"*"}
	)

	db := ctx.DB().Model(entity.Role{}).Select(fs)
	if req.Ids != nil {
		db = db.Where("id in ?", req.Ids)
	}
	if req.Name != nil {
		db = db.Where("name LIKE ?", *req.Name+"%")
	}

	return es, db.Find(&es).Error
}

// CreateRole 创建数据
func (r *RoleInfra) CreateRole(ctx kratosx.Context, role *entity.Role) (uint32, error) {
	return role.Id, ctx.Transaction(func(ctx kratosx.Context) error {
		if err := ctx.DB().Create(role).Error; err != nil {
			return err
		}
		return r.appendRoleChildren(ctx, role.ParentId, role.Id)
	})
}

// UpdateRole 更新数据
func (r *RoleInfra) UpdateRole(ctx kratosx.Context, req *entity.Role) error {
	if req.Id == req.ParentId {
		return errors.New("父级不能为自己")
	}
	old, err := r.GetRole(ctx, req.Id)
	if err != nil {
		return err
	}

	return ctx.Transaction(func(ctx kratosx.Context) error {
		if old.ParentId != req.ParentId {
			if err := r.removeRoleParent(ctx, req.Id); err != nil {
				return err
			}
			if err := r.appendRoleChildren(ctx, req.ParentId, req.Id); err != nil {
				return err
			}
		}
		return ctx.DB().Updates(req).Error
	})
}

// UpdateRoleStatus 更新数据状态
func (r *RoleInfra) UpdateRoleStatus(ctx kratosx.Context, id uint32, status bool) error {
	return ctx.DB().Model(entity.Role{}).Where("id=?", id).Update("status", status).Error
}

// DeleteRole 删除数据
func (r *RoleInfra) DeleteRole(ctx kratosx.Context, id uint32) error {
	ids, err := r.GetRoleChildrenIds(ctx, id)
	if err != nil {
		return err
	}
	ids = append(ids, id)
	return ctx.DB().Where("id in ?", ids).Delete(&entity.Role{}).Error
}

// GetRoleChildrenIds 获取指定id的所有子id
func (r *RoleInfra) GetRoleChildrenIds(ctx kratosx.Context, id uint32) ([]uint32, error) {
	var ids []uint32
	return ids, ctx.DB().Model(entity.RoleClosure{}).
		Select("children").
		Where("parent=?", id).
		Scan(&ids).Error
}

// GetRoleParentIds 获取指定id的所有父id
func (r *RoleInfra) GetRoleParentIds(ctx kratosx.Context, id uint32) ([]uint32, error) {
	var ids []uint32
	return ids, ctx.DB().Model(entity.RoleClosure{}).
		Select("parent").
		Where("children=?", id).
		Scan(&ids).Error
}

// appendRoleChildren 添加id到指定的父id下
func (r *RoleInfra) appendRoleChildren(ctx kratosx.Context, pid uint32, id uint32) error {
	list := []*entity.RoleClosure{
		{
			Parent:   pid,
			Children: id,
		},
	}
	ids, _ := r.GetRoleParentIds(ctx, pid)
	for _, item := range ids {
		list = append(list, &entity.RoleClosure{
			Parent:   item,
			Children: id,
		})
	}
	return ctx.DB().Create(&list).Error
}

// removeRoleParent 删除指定id的所有父层级
func (r *RoleInfra) removeRoleParent(ctx kratosx.Context, id uint32) error {
	return ctx.DB().Delete(&entity.RoleClosure{}, "children=?", id).Error
}

// GetRoleMenuIds 获取指定角色的所有id
func (r *RoleInfra) GetRoleMenuIds(ctx kratosx.Context, id uint32) ([]uint32, error) {
	var ids []uint32
	return ids, ctx.DB().Model(entity.RoleMenu{}).
		Select("menu_id").
		Where("role_id=?", id).
		Scan(&ids).Error
}

// UpdateRoleMenu 更新所有角色的id
func (r *RoleInfra) UpdateRoleMenu(ctx kratosx.Context, roleId uint32, menuIds []uint32) error {
	var list []*entity.RoleMenu
	for _, mid := range menuIds {
		list = append(list, &entity.RoleMenu{
			RoleId: roleId,
			MenuId: mid,
		})
	}

	return ctx.Transaction(func(ctx kratosx.Context) error {
		if err := ctx.DB().Delete(entity.RoleMenu{}, "role_id=?", roleId).Error; err != nil {
			return err
		}
		if err := ctx.DB().Create(&list).Error; err != nil {
			return err
		}
		return nil
	})
}

func (r *RoleInfra) GetRoleChildrenKeywords(ctx kratosx.Context, id uint32) ([]string, error) {
	ids, err := r.GetRoleChildrenIds(ctx, id)
	if err != nil {
		return nil, err
	}
	ids = append(ids, id)

	// 获取全部keyword
	var keywords []string
	return keywords, ctx.DB().Model(entity.Role{}).
		Select("keyword").
		Where("id in ?", ids).
		Scan(&keywords).Error
}

func (r *RoleInfra) GetRoleDataScope(ctx kratosx.Context, rid uint32) (bool, []uint32, error) {
	if rid == 1 {
		return true, []uint32{}, nil
	}
	ids, err := r.GetRoleChildrenIds(ctx, rid)
	if err != nil {
		return false, nil, err
	}
	ids = append(ids, rid)
	return false, ids, nil
}

func (r *RoleInfra) HasRolePurview(ctx kratosx.Context, pid uint32, rid uint32) (bool, error) {
	all, scopes, err := r.GetRoleDataScope(ctx, pid)
	if err != nil {
		return false, err
	}
	if all {
		return true, nil
	}
	return valx.InList(scopes, rid), nil
}

func (r *RoleInfra) AllRoleKeywordByMenuId(ctx kratosx.Context, id uint32) ([]string, error) {
	var (
		keys []string
		ids  []uint32
	)

	if err := ctx.DB().Model(entity.RoleMenu{}).
		Scan("menu_id").
		Where("role_id=?", id).
		Scan(&ids).Error; err != nil {
		return nil, err
	}

	return keys, ctx.DB().Model(entity.Role{}).Select("keyword").
		Where("id in ?", ids).
		Scan(&keys).
		Error
}
