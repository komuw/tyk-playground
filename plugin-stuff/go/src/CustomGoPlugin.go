package main

import (
	"net/http"

	"github.com/TykTechnologies/tyk/log"
)

var logger = log.Get()

// AddFooBarHeader adds custom "Foo: Bar" header to the request
func AddFooBarHeader(rw http.ResponseWriter, r *http.Request) {
	logger.Info("------ AddFooBarHeader called ------")
	r.Header.Set("Foo", "Bar")
	rw.Header().Set("Omar", "IsComing")
}

func main() {}

func init() {
	logger.Info("--- Go custom plugin v4 init success! ---- ")
}
