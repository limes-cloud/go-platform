package dbs

import (
	"sync"

	"github.com/limes-cloud/kratosx"
	"google.golang.org/protobuf/proto"
	"gorm.io/gorm"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/types"
)

type UserInfra struct {
}

var (
	_UserInfra     *UserInfra
	_UserInfraOnce sync.Once
)

func NewUserInfra() repository.UserRepository {
	_UserInfraOnce.Do(func() {
		_UserInfra = &UserInfra{}
	})
	return _UserInfra
}

// GetUserByPhone 获取指定数据
func (r UserInfra) GetUserByPhone(ctx kratosx.Context, phone string) (*entity.User, error) {
	var user entity.User
	db := ctx.DB().Preload("Roles").Preload("Jobs").Preload("Department")
	return &user, db.Where("phone = ?", phone).First(&user).Error
}

// GetUserByEmail 获取指定数据
func (r UserInfra) GetUserByEmail(ctx kratosx.Context, email string) (*entity.User, error) {
	var user entity.User
	db := ctx.DB().Preload("Roles").Preload("Jobs").Preload("Department")
	return &user, db.Where("email = ?", email).First(&user).Error
}

// GetUser 获取指定的数据
func (r UserInfra) GetUser(ctx kratosx.Context, id uint32) (*entity.User, error) {
	var user entity.User
	db := ctx.DB().Preload("Roles").Preload("Jobs").Preload("Department")
	return &user, db.First(&user, id).Error
}

// GetBaseUser 获取指定的数据
func (r UserInfra) GetBaseUser(ctx kratosx.Context, id uint32) (*entity.User, error) {
	var user entity.User
	return &user, ctx.DB().First(&user, id).Error
}

// ListUser 获取列表 fixed code
func (r UserInfra) ListUser(ctx kratosx.Context, req *types.ListUserRequest) ([]*entity.User, uint32, error) {
	var (
		total int64
		fs    = []string{"*"}
		list  []*entity.User
	)

	db := ctx.DB().Model(entity.User{}).Select(fs).Preload("Role").Preload("Department")

	if req.DepartmentId != nil {
		db = db.Where("department_id = ?", *req.DepartmentId)
	}
	if req.RoleId != nil {
		db = db.Where("role_id = ?", *req.RoleId)
	}
	if req.Name != nil {
		db = db.Where("name LIKE ?", *req.Name+"%")
	}
	if req.Phone != nil {
		db = db.Where("phone = ?", *req.Phone)
	}
	if req.Email != nil {
		db = db.Where("email = ?", *req.Email)
	}
	if req.Status != nil {
		db = db.Where("status = ?", *req.Status)
	}
	if len(req.LoggedAts) == 2 {
		db = db.Where("logged_at BETWEEN ? AND ?", req.LoggedAts[0], req.LoggedAts[1])
	}
	if len(req.CreatedAts) == 2 {
		db = db.Where("created_at BETWEEN ? AND ?", req.CreatedAts[0], req.CreatedAts[1])
	}
	if req.DepartmentIds != nil {
		db = db.Where("department_id in ?", req.DepartmentIds)
	}

	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if req.OrderBy == nil || *req.OrderBy == "" {
		req.OrderBy = proto.String("id")
	}
	if req.Order == nil || *req.Order == "" {
		req.Order = proto.String("asc")
	}
	db = order(db, req.OrderBy, req.Order)
	return list, uint32(total), db.Find(&list).Error
}

// CreateUser 创建数据
func (r UserInfra) CreateUser(ctx kratosx.Context, user *entity.User) (uint32, error) {
	return user.Id, ctx.DB().Create(user).Error
}

// UpdateUser 更新数据
func (r UserInfra) UpdateUser(ctx kratosx.Context, user *entity.User) error {
	return ctx.DB().Transaction(func(tx *gorm.DB) error {
		if len(user.UserRoles) != 0 {
			if err := tx.Where("user_id=?", user.Id).Delete(entity.UserRole{}).Error; err != nil {
				return err
			}
		}
		if len(user.UserJobs) != 0 {
			if err := tx.Where("user_id=?", user.Id).Delete(entity.UserJob{}).Error; err != nil {
				return err
			}
		}
		return tx.Updates(user).Error
	})
}

// UpdateUserStatus 更新数据状态
func (r UserInfra) UpdateUserStatus(ctx kratosx.Context, id uint32, status bool) error {
	return ctx.DB().Model(entity.User{}).Where("id=?", id).Update("status", status).Error
}

// DeleteUser 删除数据
func (r UserInfra) DeleteUser(ctx kratosx.Context, id uint32) error {
	return ctx.DB().Where("id = ?", id).Delete(&entity.User{}).Error
}

func (r UserInfra) GetUserRoleIds(ctx kratosx.Context, id uint32) ([]uint32, error) {
	var ids []uint32
	return ids, ctx.DB().Model(entity.UserRole{}).Where("user_id=?", id).Scan(&ids).Error
}
