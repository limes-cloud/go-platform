package main

import (
	"log"

	"github.com/go-kratos/kratos/v2/transport/grpc"
	khttp "github.com/go-kratos/kratos/v2/transport/http"
	"github.com/limes-cloud/kratosx"
)

func main() {
	app := kratosx.New(
		kratosx.WithRegistrarServer(func(*khttp.Server, *grpc.Server) {}),
	)
	if err := app.App().Run(); err != nil {
		log.Fatal(err)
	}
}
