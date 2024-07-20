package app

import (
	"github.com/go-kratos/kratos/v2/transport/grpc"
	"github.com/go-kratos/kratos/v2/transport/http"

	"github.com/limes-cloud/manager/internal/conf"
)

type registryFunc func(c *conf.Config, hs *http.Server, gs *grpc.Server)

var registries []registryFunc

func register(fn registryFunc) {
	registries = append(registries, fn)
}

func New(c *conf.Config, hs *http.Server, gs *grpc.Server) {
	for _, registry := range registries {
		registry(c, hs, gs)
	}
}
