package main

import (
	"net/http"
	"time"
	"github.com/gin-gonic/gin"
)

var startTime = time.Now()

func main() {
    router := gin.Default()
    router.GET("/health", func(c*gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "nama":      "Rouli Elizabeth Geraldine Aritonang",
            "nrp":       "5025231021",
            "status":    "UP",
            "timestamp": time.Now().Format(time.RFC3339),
            "uptime":    time.Since(startTime).Seconds(),
        })
    })
    router.Run("0.0.0.0:8080")
}