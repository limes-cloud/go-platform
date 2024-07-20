package service

import (
	"github.com/limes-cloud/kratosx"

	"github.com/limes-cloud/manager/api/manager/errors"
	"github.com/limes-cloud/manager/internal/conf"
	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/types"
)

type DictionaryService struct {
	conf *conf.Config
	repo repository.DictionaryRepository
}

func NewDictionaryService(config *conf.Config, repo repository.DictionaryRepository) *DictionaryService {
	return &DictionaryService{conf: config, repo: repo}
}

// ListDictionary 获取字典目录列表
func (u *DictionaryService) ListDictionary(ctx kratosx.Context, req *types.ListDictionaryRequest) ([]*entity.Dictionary, uint32, error) {
	list, total, err := u.repo.ListDictionary(ctx, req)
	if err != nil {
		ctx.Logger().Warnw("msg", "list dictionary error", "err", err.Error())
		return nil, 0, errors.ListError()
	}
	return list, total, nil
}

// CreateDictionary 创建字典目录
func (u *DictionaryService) CreateDictionary(ctx kratosx.Context, req *entity.Dictionary) (uint32, error) {
	id, err := u.repo.CreateDictionary(ctx, req)
	if err != nil {
		return 0, errors.CreateError(err.Error())
	}
	return id, nil
}

// UpdateDictionary 更新字典目录
func (u *DictionaryService) UpdateDictionary(ctx kratosx.Context, req *entity.Dictionary) error {
	if err := u.repo.UpdateDictionary(ctx, req); err != nil {
		return errors.UpdateError(err.Error())
	}
	return nil
}

// DeleteDictionary 删除字典目录
func (u *DictionaryService) DeleteDictionary(ctx kratosx.Context, id uint32) error {
	if err := u.repo.DeleteDictionary(ctx, id); err != nil {
		return errors.DeleteError(err.Error())
	}
	return nil
}

// ListDictionaryValue 获取字典值目录列表
func (u *DictionaryService) ListDictionaryValue(ctx kratosx.Context, req *types.ListDictionaryValueRequest) ([]*entity.DictionaryValue, uint32, error) {
	list, total, err := u.repo.ListDictionaryValue(ctx, req)
	if err != nil {
		return nil, 0, errors.ListError(err.Error())
	}
	return list, total, nil
}

// CreateDictionaryValue 创建字典值目录
func (u *DictionaryService) CreateDictionaryValue(ctx kratosx.Context, req *entity.DictionaryValue) (uint32, error) {
	id, err := u.repo.CreateDictionaryValue(ctx, req)
	if err != nil {
		return 0, errors.CreateError(err.Error())
	}
	return id, nil
}

// UpdateDictionaryValue 更新字典值目录
func (u *DictionaryService) UpdateDictionaryValue(ctx kratosx.Context, req *entity.DictionaryValue) error {
	if err := u.repo.UpdateDictionaryValue(ctx, req); err != nil {
		return errors.UpdateError(err.Error())
	}
	return nil
}

// UpdateDictionaryValueStatus 更新字典值目录状态
func (u *DictionaryService) UpdateDictionaryValueStatus(ctx kratosx.Context, id uint32, status bool) error {
	if err := u.repo.UpdateDictionaryValueStatus(ctx, id, status); err != nil {
		return errors.UpdateError(err.Error())
	}
	return nil
}

// DeleteDictionaryValue 删除字典值目录
func (u *DictionaryService) DeleteDictionaryValue(ctx kratosx.Context, id uint32) error {
	if err := u.repo.DeleteDictionaryValue(ctx, id); err != nil {
		return errors.DeleteError(err.Error())
	}
	return nil
}

// GetDictionary 获取指定的字典目录
func (u *DictionaryService) GetDictionary(ctx kratosx.Context, req *types.GetDictionaryRequest) (*entity.Dictionary, error) {
	var (
		res *entity.Dictionary
		err error
	)

	if req.Id != nil {
		res, err = u.repo.GetDictionary(ctx, *req.Id)
	} else if req.Keyword != nil {
		res, err = u.repo.GetDictionaryByKeyword(ctx, *req.Keyword)
	} else {
		return nil, errors.ParamsError()
	}

	if err != nil {
		return nil, errors.GetError(err.Error())
	}
	return res, nil
}

// GetDictionaryValues 获取字典值目录列表
func (u *DictionaryService) GetDictionaryValues(ctx kratosx.Context, keywords []string) (map[string][]*entity.DictionaryValue, error) {
	var reply = make(map[string][]*entity.DictionaryValue)
	for _, key := range keywords {
		values, err := u.repo.AllDictionaryValue(ctx, key)
		if err != nil {
			return nil, errors.GetError(err.Error())
		}
		reply[key] = values
	}
	return reply, nil
}
