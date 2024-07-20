package dbs

import (
	"fmt"

	"google.golang.org/protobuf/proto"
	"gorm.io/gorm"
)

func order(db *gorm.DB, orderBy, order *string) *gorm.DB {
	if orderBy == nil || *orderBy == "" {
		orderBy = proto.String("id")
	}
	if order == nil || *order == "" {
		order = proto.String("asc")
	}
	db = db.Order(fmt.Sprintf("%s %s", *orderBy, *order))

	// 追加id排序，避免在非唯一索引排序时，同等值的数据排序不稳定造成分页数据异常
	if *orderBy != "id" {
		db = db.Order("id asc")
	}
	return db
}
