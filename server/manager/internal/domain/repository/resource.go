package repository

import (
	"github.com/limes-cloud/kratosx"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/types"
)

type ResourceRepository interface {
	// GetResourceScopes 获取指定用户的资源权限
	GetResourceScopes(ctx kratosx.Context, req *types.GetResourceScopesRequest) ([]uint32, error)

	// GetResource 获取资源权限
	GetResource(ctx kratosx.Context, req *types.GetResourceRequest) ([]uint32, error)

	// DeleteResource 删除资源权限
	DeleteResource(ctx kratosx.Context, req *types.DeleteResourceRequest) error

	// CreateResources 添加资源权限
	CreateResources(ctx kratosx.Context, list []*entity.Resource) error
}
