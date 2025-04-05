<div align=center>
  
# Laporan Penugasan Modul 1 - Modul CI/CD - OPREC NETICS 2025

</div>

#### `main.go`
```c
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
            "nama":      "Pikachu",
            "nrp":       "5025231021",
            "status":    "UP",
            "timestamp": time.Now().Format(time.RFC3339),
            "uptime":    time.Since(startTime).String(),
        })
    })
    router.Run("0.0.0.0:8080")
}
```
Penjelasan:
1. Kode diatas merupakan kode Go kamu yang membuat API dengan endpoint `/health`. Pada file Go ini digunakan framework Gin Gonic.
2. Framework Gin Gonic digunakan agar lebih minimalis dan cepat
3. Variabel `startTime` digunakan untuk menyimpan timestamp saat server dijalankan.
4. Kode Go ini akan menjalankan server Gin pada `IP 0.0.0.0` port `8080`. 0.0.0.0 agar server bisa diakses dari alamat IP manapun, cocok untuk container/VPS.

#### `Dockerfile`
```c
FROM golang:1.24.2-alpine3.21 AS builder
WORKDIR /build
COPY . .
RUN go mod download
RUN go build -ldflags="-s -w" -o ./health-api


FROM gcr.io/distroless/base-debian12
WORKDIR /app
COPY --from=builder /build/health-api ./health-api
EXPOSE 8080
CMD ["/app/health-api"]
```
Penjelasan:
1. Dockerfile diatas menggunakan multi-stage build, sesuai dengan perintah penugasan. Hal ini juga untuk membuat image menjadi lebih ringan dibandingkan dengan Dockerfile biasa dan production-ready.
2. Terdapat 2 stage pada dockerfile, yakni builder stage dan production image.
3. Stage pertama dimulai dari `FROM golang:1.24.2-alpine3.21 AS builder` sampai `RUN go build -ldflags="-s -w" -o ./health-api`. Stage ini digunakan untuk build/compile binary dari source Go di image Alpine
4. Stage kedua dimulai dari `FROM gcr.io/distroless/base-debian12` sampai `CMD ["/app/health-api"]`. Stage ini digunakan untuk menyimpan binary hasil compile stage pertama, lalu deploy binary ke image `distroless`.
5. Keuntungan menggunakan multi stage build adalah lebih ringan dan aman.

#### `.github/workflows/deploy.yaml`
Ini merupakan CI/CD pipeline menggunakan github actions untuk melakukan otomasi proses deployment API. API tersebut di deploy dalam bentuk container (Docker Multi-stage) pada VPS publik (Azure). Terdapat 3 jobs utama pada CI/CD pipeline ini yaitu `build-and-test`, `build-and-push-image`, dan `deploy`.
###### build-and-test
```c
  build-and-test:
    name: Build and Test
    runs-on: ubuntu-latest

    steps:
      - name: Run actions/checkout@v4
        uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: 1.24.2

      - name: Verify and tidy dependencies
        run: |
            go mod tidy
            go mod verify
        
      - name: Run tests
        run: go test -v ./...

      - name: Build application
        run: go build -v -o health-api
```
Penjelasan:
1. Job ini digunakan untuk build dan test aplikasi Go.
2. Steps `Run actions/checkout@v4` digunakan untuk meng-clone-kan repository ke runner (ubuntu).
3. Steps `Set up Go` digunakan untuk install Go version di Github Actions.
4. Steps `Verify and tidy dependencies` digunakan untuk verifikasi dependencies dan membersihkan `go.mod` serta `go.sum`.
5. Steps `Run tests` digunakan untuk menjalankan test (bila ada).
6. Steps `Build application` digunakan untuk build binary dari Go dengan output yaitu `health-api`.

###### build-and-push-image
```c
build-and-push-image:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    needs: build-and-test

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/health-app:latest
```
Penjelasan:
1. Job ini digunakan untuk build dan push docker image ke docker hub, karena nantinya akan di deploy dalam bentuk container ke VPS publik.
2. Job ini berjalan jika dan hanya jika `build-and-test` (job sebelumnya) sukses dijalankan.
3. Step `Check out repository` digunakan untuk mengecek repository.
4. Step `Log in to Docker Hub` digunakan untuk login ke akun Docker Hub dengan kredential username dan password.
5. Step `Set up Docker Buildx` digunakan untuk build image pada docker multi-stage.
6. Step `Build and Push Docker Image` digunakan untuk build Docker image dari direktori project (.). Setelah itu image akan di push ke Docker Hub dengan tag latest.

###### deploy
```c
- name: Deploy to Server (SSH)
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.VM_HOST }}
          username: ${{ secrets.VM_USER }}
          key: ${{ secrets.VM_SSH_KEY }}
          script: |
            docker pull ${{ secrets.DOCKER_USERNAME }}/health-app:latest
            docker stop health-api || true
            docker rm health-api || true
            docker run -d --name health-api -p 8080:8080 ${{ secrets.DOCKER_USERNAME }}/health-app:latest

      - name: Verify deployment
        run: curl --fail http://${{ secrets.VM_HOST }}:8080/health
```
Penjelasan:
1. Job ini digunakan untuk menjalankan proses deploy ke VPS publik via SSH. VPS publik pada tugas ini menggunakan VPS dari Azure.
2. Job ini berjalan jika dan hanya jika `build-and-push-image` (job sebelumnya) sukses dijalankan.
3. Step `Deploy to Server` digunakan untuk login ke server VPS menggunakan SSH. Kita perlu memasukkan 3 kredential yaitu `VM_HOST` atau IP VPS publik, `VM_USER`, serta `VM_SSH_KEY`.
4. Step `Verify Deployment` digunakan untuk mengecek apakah API berhasil dideploy dan sudah bisa berjalan. Hal ini dilakukan dengan send request ke endpoint `/health`.
