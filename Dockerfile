FROM golang:1.24.2-alpine3.21 AS builder
WORKDIR /build
COPY go.mod go.sum ./ 
RUN go mod download
COPY . . 
RUN go build -o health-api


FROM gcr.io/distroless/base-debian12
WORKDIR /app
COPY --from=builder /build/health-api ./health-api
EXPOSE 8080
CMD ["/app/health-api"]