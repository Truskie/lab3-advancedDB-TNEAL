package main

import (
	"log"
	"net/http"

	"lab2-terrylneal/internal/routes"
)

func main() {
	mux := http.NewServeMux()

	//setting up routes
	routes.SetupRoutes(mux)

	//applying the middleware to the routes
	handler := routes.ApplyMiddleware(mux)

	log.Print("Server Starting on :4000")
	err := http.ListenAndServe(":4000", handler)
	log.Fatal(err)
}
