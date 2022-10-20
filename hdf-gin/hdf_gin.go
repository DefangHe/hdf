package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"net/http"
	"time"
)

func main() {
	router := gin.Default()

	str := "root:123456@(192.169.0.87:3306)/3hhdf?charset=utf8mb4\u0026parseTime=True\u0026loc=Local"
	if err := Database(str); err != nil {
		fmt.Printf("数据库初始化错误:", err.Error())
		return
	}

	router.GET("/", func(c *gin.Context) {
		c.String(http.StatusOK, "Hello World hdf")
	})

	stats := DB.DB().Stats()
	fmt.Printf("stats ======= 2786782 : %v\n", stats)

	go Create("hdf", "123456", "路人甲")

	time.Sleep(time.Second * 1)
	stats = DB.DB().Stats()
	fmt.Printf("stats ======= 2786782 : %v\n", stats)

	router.Run(":8090")
}
