package dbs

import (
	"sync"

	"github.com/limes-cloud/kratosx"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/types"
)

type RbacInfra struct {
}

var (
	_RbacInfra     *RbacInfra
	_RbacInfraOnce sync.Once
)

func NewRbacInfra() repository.RbacRepository {
	_RbacInfraOnce.Do(func() {
		_RbacInfra = &RbacInfra{}
	})
	return _RbacInfra
}

func (r *RbacInfra) CreateRbacRolesApi(ctx kratosx.Context, roles []string, req types.MenuApi) error {
	defer ctx.Authentication().Enforce().LoadPolicy()

	var list []*entity.CasbinRule
	for _, role := range roles {
		list = append(list, &entity.CasbinRule{
			Ptype: "p",
			V0:    role,
			V1:    req.Api,
			V2:    req.Method,
		})
	}
	return ctx.DB().Create(&list).Error
}

func (r *RbacInfra) DeleteRbacApi(ctx kratosx.Context, api, method string) error {
	defer ctx.Authentication().Enforce().LoadPolicy()

	return ctx.DB().Where("v1=? and v2=?", api, method).Delete(entity.CasbinRule{}).Error
}

func (r *RbacInfra) UpdateRbacApi(ctx kratosx.Context, old types.MenuApi, now types.MenuApi) error {
	defer ctx.Authentication().Enforce().LoadPolicy()

	return ctx.DB().
		Model(entity.CasbinRule{}).
		Where("v1=? and v2=?", old.Api, old.Method).
		UpdateColumn("v1", now.Api).
		UpdateColumn("v2", now.Method).
		Error
}

func (r *RbacInfra) UpdateRbacRoleApis(ctx kratosx.Context, role string, apis []*types.MenuApi) error {
	var list []*entity.CasbinRule
	for _, item := range apis {
		list = append(list, &entity.CasbinRule{
			Ptype: "p",
			V0:    role,
			V1:    item.Api,
			V2:    item.Method,
		})
	}

	return ctx.Transaction(func(ctx kratosx.Context) error {
		defer ctx.Authentication().Enforce().LoadPolicy()
		if err := ctx.DB().Where("v0=?", role).Delete(&entity.CasbinRule{}).Error; err != nil {
			return err
		}
		return ctx.DB().Create(&list).Error
	})
}

func (r *RbacInfra) DeleteRbacRoles(ctx kratosx.Context, roles []string) error {
	defer ctx.Authentication().Enforce().LoadPolicy()
	return ctx.DB().Where("v0 in ?", roles).Delete(&entity.CasbinRule{}).Error
}
