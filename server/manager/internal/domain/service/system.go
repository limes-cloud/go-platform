package service

import (
	"github.com/limes-cloud/kratosx"

	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/types"
)

type SystemService struct {
	conf *conf.Config
	dict repository.DictionaryRepository
}

func NewSystemService(config *conf.Config, dict repository.DictionaryRepository) *SystemService {
	return &SystemService{conf: config, dict: dict}
}

// GetSystemSetting 获取系统设置
func (u *SystemService) GetSystemSetting(ctx kratosx.Context, _ *types.GetSystemSettingRequest) *types.GetSystemSettingReply {
	setting := u.conf.Setting
	reply := types.GetSystemSettingReply{
		Debug:              setting.Debug,
		Title:              setting.Title,
		Desc:               setting.Desc,
		Copyright:          setting.Copyright,
		Logo:               setting.Logo,
		Watermark:          u.conf.Setting.Watermark,
		ChangePasswordType: u.conf.ChangePasswordType,
	}

	if len(u.conf.DictionaryKeywords) != 0 {
		dictionaries, err := u.dict.ListDictionaryValues(ctx, u.conf.DictionaryKeywords)
		if err != nil {
			ctx.Logger().Error("get dictionary error ", err.Error())
		}
		reply.Dictionaries = dictionaries
	}

	return &reply
}
