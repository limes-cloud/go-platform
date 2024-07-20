package dbs

import (
	"sync"

	"github.com/limes-cloud/kratosx"

	"github.com/limes-cloud/manager/internal/domain/entity"
	"github.com/limes-cloud/manager/internal/domain/repository"
	"github.com/limes-cloud/manager/internal/types"
)

type JobInfra struct {
}

var (
	_JobInfra     *JobInfra
	_JobInfraOnce sync.Once
)

func NewJobInfra() repository.JobRepository {
	_JobInfraOnce.Do(func() {
		_JobInfra = &JobInfra{}
	})
	return _JobInfra
}

// GetJob 获取指定的数据
func (r *JobInfra) GetJob(ctx kratosx.Context, id uint32) (*entity.Job, error) {
	var job = entity.Job{}
	return &job, ctx.DB().First(&job, id).Error
}

// GetJobByKeyword 获取指定数据
func (r *JobInfra) GetJobByKeyword(ctx kratosx.Context, keyword string) (*entity.Job, error) {
	var job = entity.Job{}
	return &job, ctx.DB().First(&job, "keyword=?", keyword).Error
}

// ListJob 获取列表
func (r *JobInfra) ListJob(ctx kratosx.Context, req *types.ListJobRequest) ([]*entity.Job, uint32, error) {
	var (
		total int64
		fs    = []string{"*"}
		ms    []*entity.Job
	)

	db := ctx.DB().Model(entity.Job{}).Select(fs)

	if req.Keyword != nil {
		db = db.Where("keyword = ?", *req.Keyword)
	}
	if req.Name != nil {
		db = db.Where("name LIKE ?", *req.Name+"%")
	}
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	db = db.Offset(int((req.Page - 1) * req.PageSize)).Limit(int(req.PageSize))
	if err := db.Find(&ms).Error; err != nil {
		return nil, 0, err
	}
	return ms, uint32(total), nil
}

// CreateJob 创建数据
func (r *JobInfra) CreateJob(ctx kratosx.Context, job *entity.Job) (uint32, error) {
	return job.Id, ctx.DB().Create(job).Error
}

// UpdateJob 更新数据
func (r *JobInfra) UpdateJob(ctx kratosx.Context, job *entity.Job) error {
	return ctx.DB().Updates(job).Error
}

// DeleteJob 删除数据
func (r *JobInfra) DeleteJob(ctx kratosx.Context, id uint32) error {
	return ctx.DB().Where("id = ?", id).Delete(&entity.Job{}).Error
}
