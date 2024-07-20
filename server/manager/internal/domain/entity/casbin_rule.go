package entity

type CasbinRule struct {
	Id    uint32 `json:"id" gorm:"column:id"`
	Ptype string `json:"ptype" gorm:"column:ptype"`
	V0    string `json:"v0" gorm:"column:v0"`
	V1    string `json:"v1" gorm:"column:v1"`
	V2    string `json:"v2" gorm:"column:v2"`
	V3    string `json:"v3" gorm:"column:v3"`
	V4    string `json:"v4" gorm:"column:v4"`
	V5    string `json:"v5" gorm:"column:v5"`
}
