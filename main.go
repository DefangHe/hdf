package main

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()

	fmt.Println("hello world !!!")

	router.GET("/", func(c *gin.Context) {
		c.String(http.StatusOK, "wellcom to guanghzou")
	})
	router.Run("127.0.0.1:8090")
}
