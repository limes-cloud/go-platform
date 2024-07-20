package md

import (
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/valx"

	"github.com/limes-cloud/manager/api/manager/errors"
)

type Auth struct {
	UserId            uint32 `json:"userId"`
	RoleId            uint32 `json:"roleId"`
	RoleKeyword       string `json:"roleKeyword"`
	DepartmentId      uint32 `json:"departmentId"`
	DepartmentKeyword string `json:"departmentKeyword"`
}

func New(info *Auth) map[string]any {
	var res map[string]any
	_ = valx.Transform(info, &res)
	return res
}

func Get(ctx kratosx.Context) *Auth {
	var (
		data Auth
		err  error
	)
	if ctx.Token() != "" {
		err = ctx.JWT().Parse(ctx, &data)
	} else {
		// 三方服务调用的时候通过auth信息获取
		err = ctx.Authentication().ParseAuth(ctx, &data)
	}
	if err != nil {
		panic(errors.ForbiddenError())
	}

	if data.UserId == 0 {
		panic(errors.ForbiddenError())
	}
	return &data
}

func UserId(ctx kratosx.Context) uint32 {
	return Get(ctx).UserId
}

func RoleId(ctx kratosx.Context) uint32 {
	return Get(ctx).RoleId
}

func RoleKeyword(ctx kratosx.Context) string {
	return Get(ctx).RoleKeyword
}

func DepartmentId(ctx kratosx.Context) uint32 {
	return Get(ctx).DepartmentId
}

func DepartmentKeyword(ctx kratosx.Context) string {
	return Get(ctx).DepartmentKeyword
}
