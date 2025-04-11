<div align=center>
  
# 🛠️Laporan Penugasan Modul 1🛠️
## Modul CI/CD - OPREC NETICS 2025

</div>

- ## Daftar Isi
- [Identitas](#identitas)
- [Overview](#overview)
- [Penjelasan Kode](#penjelasan-kode)
  - [main.go](#maingo)
  - [Dockerfile](#dockerfile)
  - [github/workflows/deploy.yaml](#githubworkflowsdeployyaml)
    - [build-and-test](#build-and-test)
    - [build-and-push-image](#build-and-push-image)
    - [deploy](#deploy)
- [Best Practices](#best-practices)
- [Kesimpulan](#kesimpulan)
- [Dokumentasi Hasil](#dokumentasi-hasil)
  - [API ENDPOINT /health](#api-endpoint-health)
  - [GitHub Actions](#github-actions)
  - [Docker Hub](#docker-hub) <br> <br>

## Identitas
- **Nama:** Rouli Elizabeth Geraldine Aritonang  
- **NRP:** 5025231021  
- **Docker Image:** [Link Docker Image on Docker Hub](https://hub.docker.com/r/eligeraldinee/health-app)  
- **URL API:** [Link Public API](http://13.75.95.111:8080/health) --> url api tidak dapat diakses untuk saat ini karena VM distop untuk alasan efisiensi credit <br> <br>

## Overview
Repository ini merupakan implementasi modul CI/CD sederhana menggunakan GitHub Actions, Docker, dan VPS publik berbasis Azure Virtual Machine. Pada tugas ini, proyek akan membangun API publik dengan endpoint `/health` yang menyajikan beberapa informasi. API dibuat menggunakan bahasa pemrograman Go dengan framework Gin. Setelah itu API akan dijadikan sebuah image Docker menggunakan teknik multi-stage build agar ukuran image menjadi minimal dan efisien. Proses build, push, dan deployment dijalankan secara otomatis melalui CI/CD pipeline pada GitHub Actions dan server Azure melalui koneksi SSH. Source code telah dibuat seefisien mungkin dengan menerapkan beberapa bestt practices pada proses CI/CD. <br> <br>

## Penjelasan Kode  
### `main.go`
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
            "nama":      "Rouli Elizabeth Geraldine Aritonang",
            "nrp":       "5025231021",
            "status":    "UP",
            "timestamp": time.Now().Format(time.RFC3339),
            "uptime":    time.Since(startTime).Truncate(time.Second).String(),
        })
    })
    router.Run("0.0.0.0:8080")
}
```
Penjelasan:
1. Kode diatas merupakan kode Go kamu yang membuat API dengan endpoint `/health`. Pada file Go ini digunakan framework Gin Gonic.
2. Framework Gin Gonic digunakan agar lebih minimalis dan cepat dalam hal response time dan request handling pada HTTP server.
3. Variabel `startTime` digunakan untuk menyimpan timestamp saat server dijalankan.
4. Kode Go ini akan menjalankan server Gin pada `IP 0.0.0.0` port `8080`. 0.0.0.0 agar server bisa diakses dari alamat IP manapun, cocok untuk container/VPS. <br> <br>

### `Dockerfile`
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
3. Stage pertama dimulai dari `FROM golang:1.24.2-alpine3.21 AS builder` sampai `RUN go build -ldflags="-s -w" -o ./health-api`. Stage ini digunakan untuk build/compile binary dari source Go di image Alpine.
4. `-ldflags="-s -w"` digunakan untuk menghilangkan simbol table dan debug info, agar nantinya binary jadi lebih kecil.
5. Stage kedua dimulai dari `FROM gcr.io/distroless/base-debian12` sampai `CMD ["/app/health-api"]`. Stage ini digunakan untuk menyimpan binary hasil compile stage pertama, lalu deploy binary ke image `distroless`.
6. Keuntungan menggunakan multi-stage build adalah lebih ringan dan aman. <br> <br>

### `.github/workflows/deploy.yaml`
Ini merupakan CI/CD pipeline menggunakan github actions untuk melakukan otomasi proses deployment API. API tersebut di deploy dalam bentuk container (Docker Multi-stage) pada VPS publik (Azure). Terdapat 3 jobs utama pada CI/CD pipeline ini yaitu `build-and-test`, `build-and-push-image`, dan `deploy`. <br> <br>
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
```
Penjelasan:
1. Job ini digunakan untuk build dan test aplikasi Go.
2. Steps `Run actions/checkout@v4` digunakan untuk mengambil source code dari repository ke dalam runner GitHub Actions.
3. Steps `Set up Go` digunakan untuk install Go version di Github Actions.
4. Steps `Verify and tidy dependencies` digunakan untuk verifikasi dependencies dan membersihkan `go.mod` serta `go.sum`.
5. Steps `Run tests` digunakan untuk menjalankan semua test (bila ada) yang saat ini belum ada. <br> <br>

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
3. Step `Check out repository` digunakan untuk mengambil source code dari repository ke dalam runner GitHub Actions.
5. Step `Log in to Docker Hub` digunakan untuk login ke akun Docker Hub dengan kredential username dan password.
6. Step `Set up Docker Buildx` digunakan untuk build image pada docker multi-stage. Step ini dibutuhkan apabila ingin menjalankan `docker/build-push-action@v6`.
7. Step `Build and Push Docker Image` digunakan untuk build Docker image dari direktori project (.). Setelah itu image akan di push ke Docker Hub dengan tag latest. <br> <br>

###### deploy
```c
- name: Deploy to Server (SSH)
        uses: appleboy/ssh-action@v1
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
1. Job ini digunakan untuk menjalankan proses deploy ke VPS publik via SSH. VPS publik pada tugas ini menggunakan VPS gratis dari Azure.
2. Job ini berjalan jika dan hanya jika `build-and-push-image` (job sebelumnya) sukses dijalankan.
3. Step `Deploy to Server` digunakan untuk login ke server VPS menggunakan SSH. Kita perlu memasukkan 3 kredential yaitu `VM_HOST` atau IP VPS publik, `VM_USER`, serta `VM_SSH_KEY`. Setelah itu proses pull image, stop container, remove container, dan menjalankan container baru akan dilakukan.
4. Step `Verify Deployment` digunakan untuk mengecek apakah API berhasil dideploy dan sudah bisa berjalan. Hal ini dilakukan dengan send request ke endpoint `/health`. <br> <br>

## Best Practices
1.  Memisahkan job build/test dan deploy agar lebih jelas saat prosesnya ditampilkan.
2.  Memakai `needs` antar setiap job agar job dapat dipastikan berjalan berurutan.
3.  Menggunakan beberapa `secrets` untuk data-data sensitif.
4.  Menggunakan verifikasi deploy menggunakan curl di akhir actions. <br> <br>

## Kesimpulan
Pada source code ini, proses build, test, push, dan deploy berhasil diotomasi menggunakan Github Actions dan Docker pada Azure VPS. Dengan begitu, setiap perubahan yang ada pada branch main akan terupdate dengan mudah pada API publik. Dengan adanya CI/CD, proses keseluruhan deployment akan menjadi lebih mudah dan cepat bagi para developer, karena tidak perlu melakukan keseluruhan proses deployment satu-per-satu secara manual. <br> <br>

## Dokumentasi hasil
###### API ENDPOINT /HEALTH
![image](https://github.com/user-attachments/assets/5020b36b-3c24-4820-8fd8-173c3493010c)

###### GITHUB ACTIONS
![Screenshot 2025-04-06 163414](https://github.com/user-attachments/assets/82954cd6-c7d6-43ae-88ad-0e97fdaf1673)

![image](https://github.com/user-attachments/assets/68d579f6-210e-4667-89a3-d0cec3c8a79d)

![Screenshot 2025-04-06 163710](https://github.com/user-attachments/assets/f1cc3b78-0fa8-4db1-af29-8dc61392ed44)

![image](https://github.com/user-attachments/assets/aa7f65f3-987a-497f-aeba-44b16b45cf70)

###### DOCKER HUB
![image](https://github.com/user-attachments/assets/9ffd247d-db16-4287-a044-53cd4e583aba)
