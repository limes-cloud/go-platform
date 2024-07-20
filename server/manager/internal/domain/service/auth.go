package service

import (
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/valx"

	"github.com/limes-cloud/manager/api/manager/errors"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/pkg/md"
	"github.com/limes-cloud/manager/internal/types"
)

type AuthService struct {
	conf *conf.Config
}

func NewAuthService(conf *conf.Config) *AuthService {
	return &AuthService{
		conf: conf,
	}
}

// Auth 外部接口鉴权
func (u *AuthService) Auth(ctx kratosx.Context, in *types.AuthRequest) (*md.Auth, error) {
	info := md.Get(ctx)

	if valx.InList(ctx.Config().App().Authentication.SkipRole, info.RoleKeyword) {
		return info, nil
	}

	author := ctx.Authentication()
	if author.IsWhitelist(in.Path, in.Method) {
		return info, nil
	}

	enforce := ctx.Authentication().Enforce()
	isAuth, _ := enforce.Enforce(info.RoleKeyword, in.Path, in.Method)
	if !isAuth {
		return nil, errors.ForbiddenError()
	}

	return info, nil
}
