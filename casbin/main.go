package main

import (
	"fmt"
)

type Response struct {
	Code  int         `json:"code"`
	Data  interface{} `json:"data,omitempty"`
	Msg   string      `json:"msg"`
	Error string      `json:"error,omitempty"`
}

func main() {
	s3 := []int{0, 1, 2, 3}
	fmt.Printf("s3 的长度：%d，容量：%d\n", len(s3), cap(s3))
	s4 := []int{9: 9}
	fmt.Printf("s4 的长度：%d，容量：%d\ns4: %v\n", len(s4), cap(s4), s4)
}
