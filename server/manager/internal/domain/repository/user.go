package repository

import (
	"github.com/limes-cloud/kratosx"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/types"
)

type UserRepository interface {
	// GetUser 获取指定的用户信息
	GetUser(ctx kratosx.Context, id uint32) (*entity.User, error)

	// GetBaseUser 获取指定的用户基础信息
	GetBaseUser(ctx kratosx.Context, id uint32) (*entity.User, error)

	// GetUserByPhone 获取指定的用户信息
	GetUserByPhone(ctx kratosx.Context, phone string) (*entity.User, error)

	// GetUserByEmail 获取指定的用户信息
	GetUserByEmail(ctx kratosx.Context, email string) (*entity.User, error)

	// GetUserRoleIds 获取用户的角色id
	GetUserRoleIds(ctx kratosx.Context, id uint32) ([]uint32, error)

	// ListUser 获取用户信息列表
	ListUser(ctx kratosx.Context, req *types.ListUserRequest) ([]*entity.User, uint32, error)

	// CreateUser 创建用户信息
	CreateUser(ctx kratosx.Context, req *entity.User) (uint32, error)

	// UpdateUser 更新用户信息
	UpdateUser(ctx kratosx.Context, req *entity.User) error

	// UpdateUserStatus 更新用户信息状态
	UpdateUserStatus(ctx kratosx.Context, id uint32, status bool) error

	// DeleteUser 删除用户信息
	DeleteUser(ctx kratosx.Context, id uint32) error
}
