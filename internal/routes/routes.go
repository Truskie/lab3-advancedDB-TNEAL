package routes

import (
	"net/http"

	"lab2-terrylneal/internal/handlers"
	"lab2-terrylneal/internal/middleware"
)

// setting up the routes
func SetupRoutes(mux *http.ServeMux) *http.ServeMux {
	if mux == nil {
		mux = http.NewServeMux()
	}
	mux.HandleFunc("/", handlers.Home)
	mux.HandleFunc("/about", handlers.About)
	mux.HandleFunc("/contact", handlers.Contact)
	mux.HandleFunc("/hobby", handlers.Hobby)

	//json
	mux.HandleFunc("/api/info", handlers.APIInfo)
	mux.HandleFunc("/api/users", handlers.GetUsers)
	mux.HandleFunc("/api/users/create", handlers.CreateUser)

	var handler http.Handler = mux
	handler = middleware.LoggingMiddleware(handler)
	handler = middleware.TimingMiddleware(handler)

	return mux
}

// applying hte middleware
func ApplyMiddleware(handler http.Handler) http.Handler {
	handler = middleware.LoggingMiddleware(handler)
	handler = middleware.TimingMiddleware(handler)
	return handler
}
