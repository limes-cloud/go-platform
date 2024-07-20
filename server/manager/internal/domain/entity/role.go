package entity

import (
	"github.com/limes-cloud/kratosx/pkg/tree"
	"github.com/limes-cloud/kratosx/types"
)

type Role struct {
	ParentId      uint32  `json:"parentId" gorm:"column:parent_id"`
	Name          string  `json:"name" gorm:"column:name"`
	Keyword       string  `json:"keyword" gorm:"column:keyword"`
	Status        *bool   `json:"status" gorm:"column:status"`
	DataScope     string  `json:"dataScope" gorm:"column:data_scope"`
	DepartmentIds *string `json:"departmentIds" gorm:"column:department_ids"`
	Description   *string `json:"description" gorm:"column:description"`
	Children      []*Role `json:"Children" gorm:"-"`
	types.BaseModel
}

type RoleMenu struct {
	Id     uint32 `json:"id" gorm:"column:id"`
	MenuId uint32 `json:"menu_id" gorm:"column:menu_id"`
	RoleId uint32 `json:"role_id" gorm:"column:role_id"`
}

type RoleClosure struct {
	ID       uint32 `json:"id" gorm:"column:id"`
	Parent   uint32 `json:"parent" gorm:"column:parent"`
	Children uint32 `json:"children" gorm:"column:children"`
}

// ID 获取ID
func (m *Role) ID() uint32 {
	return m.Id
}

// Parent 获取父ID
func (m *Role) Parent() uint32 {
	return m.ParentId
}

// AppendChildren 添加子节点
func (m *Role) AppendChildren(child any) {
	menu := child.(*Role)
	m.Children = append(m.Children, menu)
}

// ChildrenNode 获取子节点
func (m *Role) ChildrenNode() []tree.Tree {
	var list []tree.Tree
	for _, item := range m.Children {
		list = append(list, item)
	}
	return list
}
