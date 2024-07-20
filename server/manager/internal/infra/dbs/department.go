package dbs

import (
	"errors"
	"strings"
	"sync"

	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/pkg/valx"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/types"
)

const (
	DataScopeAll         = "ALL"      // 所有部门
	DataScopeCurrent     = "CUR"      // 当前部门
	DataScopeCurrentDown = "CUR_DOWN" // 当前部门以及下级部门
	DataScopeDown        = "DOWN"     // 下级部门
	DataScopeCustom      = "CUSTOM"   // 自定义权限
)

type DepartmentInfra struct {
}

var (
	_DepartmentInfra     *DepartmentInfra
	_DepartmentInfraOnce sync.Once
)

func NewDepartmentInfra() repository.DepartmentRepository {
	_DepartmentInfraOnce.Do(func() {
		_DepartmentInfra = &DepartmentInfra{}
	})
	return _DepartmentInfra
}

// GetDepartment 获取指定的数据
func (r DepartmentInfra) GetDepartment(ctx kratosx.Context, id uint32) (*entity.Department, error) {
	var (
		ent = entity.Department{}
		fs  = []string{"*"}
	)
	return &ent, ctx.DB().Select(fs).First(&ent, id).Error
}

// GetDepartmentByKeyword 获取指定数据
func (r DepartmentInfra) GetDepartmentByKeyword(ctx kratosx.Context, keyword string) (*entity.Department, error) {
	var (
		m  = entity.Department{}
		fs = []string{"*"}
	)
	return &m, ctx.DB().Select(fs).Where("keyword = ?", keyword).First(&m).Error
}

// ListDepartment 获取列表 fixed code
func (r DepartmentInfra) ListDepartment(ctx kratosx.Context, req *types.ListDepartmentRequest) ([]*entity.Department, error) {
	var (
		ms []*entity.Department
		fs = []string{"*"}
	)

	db := ctx.DB().Model(entity.Department{}).Select(fs)

	if req.Name != nil {
		db = db.Where("name LIKE ?", *req.Name+"%")
	}
	if req.Keyword != nil {
		db = db.Where("keyword = ?", *req.Keyword)
	}
	if req.Ids != nil {
		db = db.Where("id in ?", req.Ids)
	}

	return ms, db.Find(&ms).Error
}

// CreateDepartment 创建数据
func (r DepartmentInfra) CreateDepartment(ctx kratosx.Context, req *entity.Department) (uint32, error) {
	return req.Id, ctx.Transaction(func(ctx kratosx.Context) error {
		if err := ctx.DB().Create(req).Error; err != nil {
			return err
		}
		return r.appendDepartmentChildren(ctx, req.ParentId, req.Id)
	})
}

// UpdateDepartment 更新数据
func (r DepartmentInfra) UpdateDepartment(ctx kratosx.Context, req *entity.Department) error {
	if req.Id == req.ParentId {
		return errors.New("父级不能为自己")
	}
	old, err := r.GetDepartment(ctx, req.Id)
	if err != nil {
		return err
	}

	return ctx.Transaction(func(ctx kratosx.Context) error {
		if old.ParentId != req.ParentId {
			if err := r.removeDepartmentParent(ctx, req.Id); err != nil {
				return err
			}
			if err := r.appendDepartmentChildren(ctx, req.ParentId, req.Id); err != nil {
				return err
			}
		}
		return ctx.DB().Updates(req).Error
	})
}

// DeleteDepartment 删除数据
func (r DepartmentInfra) DeleteDepartment(ctx kratosx.Context, id uint32) error {
	ids, err := r.GetDepartmentChildrenIds(ctx, id)
	if err != nil {
		return err
	}
	ids = append(ids, id)
	return ctx.DB().Where("id in ?", ids).Delete(&entity.Department{}).Error
}

// GetDepartmentChildrenIds 获取指定id的所有子id
func (r DepartmentInfra) GetDepartmentChildrenIds(ctx kratosx.Context, id uint32) ([]uint32, error) {
	var ids []uint32
	return ids, ctx.DB().Model(entity.DepartmentClosure{}).
		Select("children").
		Where("parent=?", id).
		Scan(&ids).Error
}

// GetDepartmentParentIds 获取指定id的所有父id
func (r DepartmentInfra) GetDepartmentParentIds(ctx kratosx.Context, id uint32) ([]uint32, error) {
	var ids []uint32
	return ids, ctx.DB().Model(entity.DepartmentClosure{}).
		Select("parent").
		Where("children=?", id).
		Scan(&ids).Error
}

// appendDepartmentChildren 添加id到指定的父id下
func (r DepartmentInfra) appendDepartmentChildren(ctx kratosx.Context, pid uint32, id uint32) error {
	list := []*entity.DepartmentClosure{
		{
			Parent:   pid,
			Children: id,
		},
	}
	ids, _ := r.GetDepartmentParentIds(ctx, pid)
	for _, item := range ids {
		list = append(list, &entity.DepartmentClosure{
			Parent:   item,
			Children: id,
		})
	}
	return ctx.DB().Create(&list).Error
}

// removeDepartmentParent 删除指定id的所有父层级
func (r DepartmentInfra) removeDepartmentParent(ctx kratosx.Context, id uint32) error {
	return ctx.DB().Delete(&entity.DepartmentClosure{}, "children=?", id).Error
}

func (r DepartmentInfra) GetDepartmentDataScope(ctx kratosx.Context, uid uint32) (bool, []uint32, error) {
	user := entity.User{}
	if err := ctx.DB().
		Select([]string{"role_id", "department_id"}).
		First(&user, uid).Error; err != nil {
		return false, nil, err
	}

	role := entity.Role{}
	if err := ctx.DB().
		Select([]string{"data_scope"}).
		First(&role, "id=?", user.RoleId).Error; err != nil {
		return false, nil, err
	}

	if role.DataScope == DataScopeAll {
		return true, []uint32{}, nil
	}

	if role.DataScope == DataScopeCurrentDown && user.DepartmentId == 1 {
		return true, []uint32{}, nil
	}

	switch role.DataScope {
	case DataScopeAll:
		ids := make([]uint32, 0)
		if err := ctx.DB().Select("id").Model(entity.Department{}).Scan(&ids).Error; err != nil {
			return false, nil, err
		}
		return false, ids, nil
	case DataScopeCurrent:
		return false, []uint32{user.DepartmentId}, nil
	case DataScopeCurrentDown:
		ids, err := r.GetDepartmentChildrenIds(ctx, user.DepartmentId)
		if err != nil {
			return false, nil, err
		}
		ids = append(ids, user.DepartmentId)
		return false, ids, nil
	case DataScopeDown:
		ids, err := r.GetDepartmentChildrenIds(ctx, user.DepartmentId)
		if err != nil {
			return false, nil, err
		}
		return false, ids, nil
	case DataScopeCustom:
		if role.DepartmentIds == nil {
			return false, []uint32{}, nil
		}
		ids := make([]uint32, 0)
		arr := strings.Split(*role.DepartmentIds, ",")
		for _, id := range arr {
			ids = append(ids, valx.ToUint32(id))
		}
		return false, ids, nil
	}
	return false, []uint32{}, nil
}

func (r DepartmentInfra) HasDepartmentPurview(ctx kratosx.Context, uid uint32, did uint32) (bool, error) {
	all, scopes, err := r.GetDepartmentDataScope(ctx, uid)
	if err != nil {
		return false, err
	}
	if all {
		return true, nil
	}

	return valx.InList(scopes, did), nil
}
