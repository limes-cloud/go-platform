package entity

import "github.com/limes-cloud/kratosx/types"

type Job struct {
	Keyword     string  `json:"keyword" gorm:"column:keyword"`
	Name        string  `json:"name" gorm:"column:name"`
	Weight      *int32  `json:"weight" gorm:"column:weight"`
	Description *string `json:"description" gorm:"column:description"`
	types.BaseModel
}
