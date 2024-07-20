package entity

import (
	"github.com/limes-cloud/kratosx/pkg/tree"
	"github.com/limes-cloud/kratosx/types"
)

type Department struct {
	ParentId    uint32        `json:"parentId" gorm:"column:parent_id"`
	Name        string        `json:"name" gorm:"column:name"`
	Keyword     string        `json:"keyword" gorm:"column:keyword"`
	Description *string       `json:"description" gorm:"column:description"`
	Children    []*Department `json:"children" gorm:"-"`
	types.BaseModel
}

type DepartmentClosure struct {
	ID       uint32 `json:"id" gorm:"column:id"`
	Parent   uint32 `json:"parent" gorm:"column:parent"`
	Children uint32 `json:"children" gorm:"column:children"`
}

// ID 获取树ID
func (m *Department) ID() uint32 {
	return m.Id
}

// Parent 获取父ID
func (m *Department) Parent() uint32 {
	return m.ParentId
}

// AppendChildren 添加子节点
func (m *Department) AppendChildren(child any) {
	menu := child.(*Department)
	m.Children = append(m.Children, menu)
}

// ChildrenNode 获取子节点
func (m *Department) ChildrenNode() []tree.Tree {
	var list []tree.Tree
	for _, item := range m.Children {
		list = append(list, item)
	}
	return list
}
