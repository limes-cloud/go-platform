package dbs

import (
	"errors"
	"sync"

	"github.com/limes-cloud/kratosx"
	"google.golang.org/protobuf/proto"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/types"
)

type MenuInfra struct {
}

var (
	_MenuInfra     *MenuInfra
	_MenuInfraOnce sync.Once
)

func NewMenuInfra() repository.MenuRepository {
	_MenuInfraOnce.Do(func() {
		_MenuInfra = &MenuInfra{}
	})
	return _MenuInfra
}

func (r MenuInfra) InitBasicMenu(ctx kratosx.Context) {
	var list []*entity.Menu
	if err := ctx.DB().Model(entity.Menu{}).Find(&list, "type=?", entity.MenuBasic).Error; err != nil {
		ctx.Logger().Errorf("init basic api error %s", err.Error())
		return
	}
	for _, item := range list {
		if item.Method != nil && item.Api != nil {
			ctx.Authentication().AddWhitelist(*item.Api, *item.Method)
		}
	}
}

// ListMenu 获取列表
func (r MenuInfra) ListMenu(ctx kratosx.Context, req *types.ListMenuRequest) ([]*entity.Menu, error) {
	var (
		ms []*entity.Menu
		fs = []string{"*"}
	)
	db := ctx.DB().Model(entity.Menu{}).Select(fs)
	if req.Title != nil {
		db = db.Where("title LIKE ?", *req.Title+"%")
	}

	db = order(db, proto.String("weight"), proto.String("desc"))
	return ms, db.Find(&ms).Error
}

// ListMenuByRoleId 获取指定的角色的菜单
func (r MenuInfra) ListMenuByRoleId(ctx kratosx.Context, id uint32) ([]*entity.Menu, error) {
	var (
		ms []*entity.Menu
		fs = []string{"*"}
	)

	db := ctx.DB().Model(entity.Menu{}).Select(fs).Where("type!=?", entity.MenuBasic)
	if id != 1 {
		var ids []uint32
		if err := ctx.DB().Model(entity.RoleMenu{}).
			Select("menu_id").
			Where("role_id=?", id).
			Scan(&ids).Error; err != nil {
			return nil, err
		}
		db = db.Where("id in ?", ids)
	}

	db = order(db, proto.String("weight"), proto.String("desc"))
	return ms, db.Find(&ms).Error
}

func (r MenuInfra) ListMenuApi(ctx kratosx.Context) ([]*types.MenuApi, error) {
	var (
		ms []*types.MenuApi
		fs = []string{"id", "api", "method"}
	)
	return ms, ctx.DB().Model(entity.Menu{}).Select(fs).Where("type=?", entity.MenuApi).Scan(&ms).Error
}

// CreateMenu 创建数据
func (r MenuInfra) CreateMenu(ctx kratosx.Context, menu *entity.Menu) (uint32, error) {
	if menu.Type == entity.MenuRoot {
		menu.ParentId = 0
	}

	return menu.Id, ctx.Transaction(func(ctx kratosx.Context) error {
		if err := ctx.DB().Create(menu).Error; err != nil {
			return err
		}

		if err := r.appendMenuChildren(ctx, menu.ParentId, menu.Id); err != nil {
			return err
		}

		return nil
	})
}

// GetMenu 获取指定的数据
func (r MenuInfra) GetMenu(ctx kratosx.Context, id uint32) (*entity.Menu, error) {
	var menu = entity.Menu{}
	return &menu, ctx.DB().First(&menu, id).Error
}

// UpdateMenu 更新数据
func (r MenuInfra) UpdateMenu(ctx kratosx.Context, menu *entity.Menu) error {
	defer func() {
		_ = ctx.Authentication().Enforce().LoadPolicy()
	}()

	if menu.Id == menu.ParentId {
		return errors.New("父级不能为自己")
	}

	// 获取之前的菜单信息
	old, err := r.GetMenu(ctx, menu.Id)
	if err != nil {
		return err
	}

	// 出现了父级菜单变化
	if old.ParentId != menu.ParentId {
		if err := r.removeMenuParent(ctx, menu.Id); err != nil {
			return err
		}
		if err := r.appendMenuChildren(ctx, menu.ParentId, menu.Id); err != nil {
			return err
		}
	}

	return ctx.DB().Updates(menu).Error
}

// DeleteMenu 删除数据
func (r MenuInfra) DeleteMenu(ctx kratosx.Context, id uint32) error {
	defer func() {
		_ = ctx.Authentication().Enforce().LoadPolicy()
	}()

	ids, err := r.GetMenuChildrenIds(ctx, id)
	if err != nil {
		return err
	}
	ids = append(ids, id)

	return ctx.DB().Where("id in ?", ids).Delete(&entity.Menu{}).Error
}

// GetMenuChildrenIds 获取指定id的所有子id
func (r MenuInfra) GetMenuChildrenIds(ctx kratosx.Context, id uint32) ([]uint32, error) {
	var ids []uint32
	return ids, ctx.DB().Model(entity.MenuClosure{}).
		Select("children").
		Where("parent=?", id).
		Scan(&ids).Error
}

func (r MenuInfra) ListMenuChildrenApi(ctx kratosx.Context, id uint32) ([]*entity.Menu, error) {
	ids, err := r.GetMenuChildrenIds(ctx, id)
	if err != nil {
		return nil, err
	}
	ids = append(ids, id)
	var list []*entity.Menu
	return list, ctx.DB().Select([]string{"id", "type", "api", "method"}).Find(&list, "id in ?", ids).Error
}

// GetMenuParentIds 获取指定id的所有父id
func (r MenuInfra) GetMenuParentIds(ctx kratosx.Context, id uint32) ([]uint32, error) {
	var ids []uint32
	return ids, ctx.DB().Model(entity.MenuClosure{}).
		Select("parent").
		Where("children=?", id).
		Scan(&ids).Error
}

// appendMenuChildren 添加id到指定的父id下
func (r MenuInfra) appendMenuChildren(ctx kratosx.Context, pid uint32, id uint32) error {
	list := []*entity.MenuClosure{
		{
			Parent:   pid,
			Children: id,
		},
	}
	ids, _ := r.GetMenuParentIds(ctx, pid)
	for _, item := range ids {
		list = append(list, &entity.MenuClosure{
			Parent:   item,
			Children: id,
		})
	}
	return ctx.DB().Create(&list).Error
}

// removeMenuParent 删除指定id的所有父层级
func (r MenuInfra) removeMenuParent(ctx kratosx.Context, id uint32) error {
	return ctx.DB().Delete(&entity.MenuClosure{}, "children=?", id).Error
}

// SetHome 重置当前树的首页节点
func (r MenuInfra) SetHome(ctx kratosx.Context, id uint32) error {
	pids, err := r.GetMenuParentIds(ctx, id)
	if err != nil {
		return err
	}

	var menu entity.Menu
	if err = ctx.DB().
		Where("id in ?", pids).
		Where("type=?", entity.MenuRoot).
		Find(&menu).Error; err != nil {
		return err
	}

	cids, err := r.GetMenuChildrenIds(ctx, menu.Id)
	if err != nil {
		return err
	}
	pids = append(pids, cids...)
	return ctx.DB().Model(entity.Menu{}).Where("id in ?", pids).Update("is_home", false).Error
}
