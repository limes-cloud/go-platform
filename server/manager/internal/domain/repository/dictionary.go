package repository

import (
	"github.com/limes-cloud/kratosx"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/types"
)

type DictionaryRepository interface {
	// ListDictionary 获取字典目录列表
	ListDictionary(ctx kratosx.Context, req *types.ListDictionaryRequest) ([]*entity.Dictionary, uint32, error)

	// CreateDictionary 创建字典目录
	CreateDictionary(ctx kratosx.Context, req *entity.Dictionary) (uint32, error)

	// UpdateDictionary 更新字典目录
	UpdateDictionary(ctx kratosx.Context, req *entity.Dictionary) error

	// DeleteDictionary 删除字典目录
	DeleteDictionary(ctx kratosx.Context, id uint32) error

	// ListDictionaryValue 获取字典值目录列表
	ListDictionaryValue(ctx kratosx.Context, req *types.ListDictionaryValueRequest) ([]*entity.DictionaryValue, uint32, error)

	// AllDictionaryValue 获取全部字典值目录列表
	AllDictionaryValue(ctx kratosx.Context, keyword string) ([]*entity.DictionaryValue, error)

	// CreateDictionaryValue 创建字典值目录
	CreateDictionaryValue(ctx kratosx.Context, req *entity.DictionaryValue) (uint32, error)

	// UpdateDictionaryValue 更新字典值目录
	UpdateDictionaryValue(ctx kratosx.Context, req *entity.DictionaryValue) error

	// UpdateDictionaryValueStatus 更新字典值目录状态
	UpdateDictionaryValueStatus(ctx kratosx.Context, id uint32, status bool) error

	// DeleteDictionaryValue 删除字典值目录
	DeleteDictionaryValue(ctx kratosx.Context, id uint32) error

	// GetDictionary 获取指定的字典目录
	GetDictionary(ctx kratosx.Context, id uint32) (*entity.Dictionary, error)

	// GetDictionaryByKeyword 获取指定的字典目录
	GetDictionaryByKeyword(ctx kratosx.Context, keyword string) (*entity.Dictionary, error)

	// ListDictionaryValues 批量获取字典
	ListDictionaryValues(ctx kratosx.Context, keywords []string) ([]*types.DictionaryValue, error)
}
