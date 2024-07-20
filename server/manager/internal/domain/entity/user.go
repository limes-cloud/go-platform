package entity

import "github.com/limes-cloud/kratosx/types"

type User struct {
	DepartmentId uint32      `json:"departmentId" gorm:"column:department_id"`
	RoleId       uint32      `json:"roleId" gorm:"column:role_id"`
	Name         string      `json:"name" gorm:"column:name"`
	Nickname     string      `json:"nickname" gorm:"column:nickname"`
	Gender       string      `json:"gender" gorm:"column:gender"`
	Avatar       *string     `json:"avatar" gorm:"column:avatar"`
	Phone        string      `json:"phone" gorm:"column:phone"`
	Email        string      `json:"email" gorm:"column:email"`
	Password     string      `json:"password" gorm:"column:password"`
	Status       *bool       `json:"status" gorm:"column:status"`
	Setting      *string     `json:"setting" gorm:"column:setting"`
	Token        *string     `json:"token" gorm:"column:token"`
	LoggedAt     int64       `json:"loggedAt" gorm:"column:logged_at"`
	UserJobs     []*UserJob  `json:"userJobs"`
	UserRoles    []*UserRole `json:"userRoles"`
	Roles        []*Role     `json:"roles" gorm:"many2many:user_role"` // fixed code
	Jobs         []*Job      `json:"jobs" gorm:"many2many:user_job"`
	Department   *Department `json:"department"`
	Role         *Role       `json:"role"`
	types.BaseModel
}

type UserJob struct {
	UserId uint32 `json:"userId" gorm:"column:user_id"`
	JobId  uint32 `json:"jobId" gorm:"column:job_id"`
}

type UserRole struct {
	UserId uint32 `json:"userId" gorm:"column:user_id"`
	RoleId uint32 `json:"roleId" gorm:"column:role_id"`
}
