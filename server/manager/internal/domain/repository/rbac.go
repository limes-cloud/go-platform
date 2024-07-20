package repository

import (
	"github.com/limes-cloud/kratosx"

	"github.com/limes-cloud/manager/internal/types"
)

type RbacRepository interface {
	// CreateRbacRolesApi 批量添加角色所属菜单权限
	CreateRbacRolesApi(ctx kratosx.Context, roles []string, api types.MenuApi) error

	// DeleteRbacApi 删除指定的菜单权限
	DeleteRbacApi(ctx kratosx.Context, api, method string) error

	// UpdateRbacApi 更新指定的菜单权限
	UpdateRbacApi(ctx kratosx.Context, old types.MenuApi, now types.MenuApi) error

	// DeleteRbacRoles 删除指定的角色列表
	DeleteRbacRoles(ctx kratosx.Context, roles []string) error

	// UpdateRbacRoleApis 更新指定角色的菜单列表
	UpdateRbacRoleApis(ctx kratosx.Context, role string, apis []*types.MenuApi) error
}
