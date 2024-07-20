package repository

import (
	"github.com/limes-cloud/kratosx"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/types"
)

type MenuRepository interface {
	// GetMenu 获取自定菜单信息
	GetMenu(ctx kratosx.Context, id uint32) (*entity.Menu, error)

	// ListMenuApi 获取菜单api信息列表
	ListMenuApi(ctx kratosx.Context) ([]*types.MenuApi, error)

	// ListMenu 获取菜单信息列表
	ListMenu(ctx kratosx.Context, req *types.ListMenuRequest) ([]*entity.Menu, error)

	// ListMenuByRoleId 获取指定角色的菜单列表
	ListMenuByRoleId(ctx kratosx.Context, id uint32) ([]*entity.Menu, error)

	// ListMenuChildrenApi 获取指定目录下的所有api
	ListMenuChildrenApi(ctx kratosx.Context, id uint32) ([]*entity.Menu, error)

	// CreateMenu 创建菜单信息
	CreateMenu(ctx kratosx.Context, req *entity.Menu) (uint32, error)

	// UpdateMenu 更新菜单信息
	UpdateMenu(ctx kratosx.Context, req *entity.Menu) error

	// DeleteMenu 删除菜单信息
	DeleteMenu(ctx kratosx.Context, id uint32) error

	// InitBasicMenu 初始化基础菜单api
	InitBasicMenu(ctx kratosx.Context)

	// SetHome 设置菜单首页
	SetHome(ctx kratosx.Context, id uint32) error
}
