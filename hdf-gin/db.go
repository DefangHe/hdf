package main

import (
	"fmt"
	"github.com/jinzhu/gorm"
	"math/rand"
	"time"

	_ "github.com/jinzhu/gorm/dialects/mysql"
)

// DB 数据库链接单例
var (
	DB *gorm.DB
)

type Hdf struct {
	gorm.Model
	ID             int    `gorm:"comment:'用户ID'"` // 用户ID
	UserName       string `gorm:"comment:'用户名'"`  // 用户名
	PasswordDigest string `gorm:"comment:'密码摘要'"` // 密码摘要
	Role           string `gorm:"comment:'角色'"`   // 角色
}

func Database(connString string) error {
	db, err := gorm.Open("mysql", connString)
	db.LogMode(true)
	// Error
	if err != nil {
		fmt.Println("error:", err.Error())
		return err
	}
	//设置连接池
	//空闲
	db.DB().SetMaxIdleConns(50)
	//打开
	db.DB().SetMaxOpenConns(100)
	//超时
	db.DB().SetConnMaxLifetime(time.Second * 30)

	DB = db

	migration()

	/*	if err = DB.Close(); err != nil {
		fmt.Println("error:", err)
		return err
	}*/

	return nil
}

func Create(name, password, role string) {

	for i := 0; i < 10; i++ {
		rand.Seed(time.Now().Unix())
		user := Hdf{
			ID:             i + 2000,
			UserName:       name,
			PasswordDigest: password,
			Role:           role,
		}

		if err := DB.Create(&user).Error; err != nil {
			fmt.Printf("插入数据错误:", err)
			return
		}
	}

	return
}

func migration() {
	// 自动迁移模式
	DB.AutoMigrate(&Hdf{})
}
