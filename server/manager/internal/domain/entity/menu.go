package entity

import (
	"github.com/limes-cloud/kratosx/pkg/tree"
	"github.com/limes-cloud/kratosx/types"
)

const (
	MenuRoot  = "R"
	MenuApi   = "A"
	MenuPage  = "M"
	MenuGroup = "G"
	MenuBasic = "BA"
)

type Menu struct {
	ParentId   uint32  `json:"parentId" gorm:"column:parent_id"`
	Title      string  `json:"title" gorm:"column:title"`
	Type       string  `json:"type" gorm:"column:type"`
	Keyword    *string `json:"keyword" gorm:"column:keyword"`
	Icon       *string `json:"icon" gorm:"column:icon"`
	Api        *string `json:"api" gorm:"column:api"`
	Method     *string `json:"method" gorm:"column:method"`
	Path       *string `json:"path" gorm:"column:path"`
	Permission *string `json:"permission" gorm:"column:permission"`
	Component  *string `json:"component" gorm:"column:component"`
	Redirect   *string `json:"redirect" gorm:"column:redirect"`
	Weight     *int32  `json:"weight" gorm:"column:weight"`
	IsHidden   *bool   `json:"isHidden" gorm:"column:is_hidden"`
	IsCache    *bool   `json:"isCache" gorm:"column:is_cache"`
	IsHome     *bool   `json:"isHome" gorm:"column:is_home"`
	IsAffix    *bool   `json:"isAffix" gorm:"column:is_affix"`
	Children   []*Menu `json:"children" gorm:"-"`
	types.BaseModel
}

type MenuClosure struct {
	ID       uint32 `json:"id" gorm:"column:id"`
	Parent   uint32 `json:"parent" gorm:"column:parent"`
	Children uint32 `json:"children" gorm:"column:children"`
}

// ID 获取ID
func (m *Menu) ID() uint32 {
	return m.Id
}

// Parent 获取父ID
func (m *Menu) Parent() uint32 {
	return m.ParentId
}

// AppendChildren 添加子节点
func (m *Menu) AppendChildren(child any) {
	menu := child.(*Menu)
	m.Children = append(m.Children, menu)
}

// ChildrenNode 获取子节点
func (m *Menu) ChildrenNode() []tree.Tree {
	var list []tree.Tree
	for _, item := range m.Children {
		list = append(list, item)
	}
	return list
}
