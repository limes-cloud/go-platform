package entity

type Resource struct {
	Id           uint32 `json:"id" gorm:"column:id"`
	Keyword      string `json:"keyword" gorm:"column:keyword"`
	DepartmentId uint32 `json:"departmentIds" gorm:"column:department_id"`
	ResourceId   uint32 `json:"resourceId" gorm:"column:resource_id"`
}
