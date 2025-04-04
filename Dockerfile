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