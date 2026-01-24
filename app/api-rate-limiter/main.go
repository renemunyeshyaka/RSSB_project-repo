package main

import (
    "context"
    "fmt"
    "log"
    "net/http"
    "os"
    "time"
    
    "github.com/go-redis/redis/v8"
    "github.com/gorilla/mux"
)

var redisClient *redis.Client
var ctx = context.Background()

func rateLimitMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        clientIP := r.RemoteAddr
        key := fmt.Sprintf("rate_limit:%s", clientIP)
        
        current, err := redisClient.Get(ctx, key).Int()
        if err == redis.Nil {
            current = 0
        }
        
        limit := 100 // requests per minute
        if current >= limit {
            http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
            return
        }
        
        redisClient.Incr(ctx, key)
        redisClient.Expire(ctx, key, time.Minute)
        
        next.ServeHTTP(w, r)
    })
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}

func readyHandler(w http.ResponseWriter, r *http.Request) {
    if err := redisClient.Ping(ctx).Err(); err != nil {
        http.Error(w, "Redis not ready", http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("READY"))
}

func mainHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("API Rate Limiter Service"))
}

func main() {
    redisHost := os.Getenv("REDIS_HOST")
    if redisHost == "" {
        redisHost = "localhost"
    }
    
    redisClient = redis.NewClient(&redis.Options{
        Addr:     fmt.Sprintf("%s:6379", redisHost),
        Password: "",
        DB:       0,
    })
    
    r := mux.NewRouter()
    r.Use(rateLimitMiddleware)
    
    r.HandleFunc("/", mainHandler)
    r.HandleFunc("/health", healthHandler)
    r.HandleFunc("/ready", readyHandler)
    
    log.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", r))
}