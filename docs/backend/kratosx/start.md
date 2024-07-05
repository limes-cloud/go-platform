kratosx 是基于kratos 进行二次封装的基础库，里面实现了常用的一些工具的封装，在常规的kratos开发过程中，初始化一个系统需要编写很多的初始化、中间件的代码，而使用kratosx，你只需要简单的修改配置文件即可使用,并且kratosx是支持配置文件实时重载的，在很多时候我们修改了配置之后无需重新启动服务，即可生效。

kratosx 并不是新的框架，而是一个工具包，他是将kratos的一些常用的方法工具进行封装，从而简化了用户对于kratos的使用难度，比如我的项目中需要限流，需要数据库，需要缓存，其实这些常用的中间件在每个服务中都需要，但是我需要在每个服务中都去实现一遍他的初始化，这样不仅仅在服务中产生了很多冗余代码，还增加了维护成本。

为了抽离这些常用的中间件在每个服务中重复实现、维护的成本，所以开发了kratosx作为整个项目的基础库。

## 项目地址
[github/kratosx](https://github.com/limes-cloud/kratosx)

## 服务启动
使用kratos启动服务非常简单，具体实现代码如下，服务启动默认会以项目中 internal/config/config.yaml作为配置文件进行启动
```go
package main

import (
	"github.com/go-kratos/kratos/v2/config/file"
	"github.com/go-kratos/kratos/v2/log"
	"github.com/go-kratos/kratos/v2/transport/grpc"
	"github.com/go-kratos/kratos/v2/transport/http"
	"github.com/limes-cloud/kratosx"
	"github.com/limes-cloud/kratosx/config"
	_ "go.uber.org/automaxprocs"

	"github.com/go-kratos/kratos-layout/internal/conf"
	"github.com/go-kratos/kratos-layout/internal/service"
)

func main() {
	app := kratosx.New(
		// 指定启动配置，
		kratosx.Config(file.NewSource("internal/conf/config.yaml")),
		// 注册服务
		kratosx.RegistrarServer(RegisterServer),
	)

	// 运行服务
	if err := app.Run(); err != nil {
		log.Fatal(err.Error())
	}
}

func RegisterServer(c config.Config, hs *http.Server, gs *grpc.Server) {
	cfg := &conf.Config{}
	// 监听配置变动
	c.ScanWatch("business", func(value config.Value) {
		if err := value.Scan(cfg); err != nil {
			log.Error("business 配置变更失败")
		} else {
			log.Error("business 配置变更成功")
		}
	})
    // 注册服务，这里是具体的注册业务的实现，根据你的业务来进行变动
	service.New(cfg, hs, gs)
}

```
为了满足更多的定制化需求，系统保留了原来的kratos的一些可选项，可以通过kratosx.Option进行使用，具体示例如下
```go
func main() {
	app := kratosx.New(
		kratosx.RegistrarServer(RegisterServer),
        // kratosx中可以使用kratos的Option方法。
		kratosx.Options(kratos.BeforeStart(func(ctx context.Context) error {
			return nil
		})),
	)

	if err := app.Run(); err != nil {
		log.Fatal(err.Error())
	}
}
```

## 指定配置
#### 从指定的文件配置中初始化服务
```go
import (
    // 引入配置中心sdk
	"github.com/limes-cloud/configure/client"
)

func main() {
    app := kratosx.New(
        // 从指定的文件中初始化服务
        kratosx.Config(file.NewSource("config/config.yaml")),
        // 注册服务
        kratosx.RegistrarServer(RegisterServer),
		// 启动之后打印启动信息
        kratosx.Options(kratos.AfterStart(func(ctx context.Context) error {
            kt := kratosx.MustContext(ctx)
            pt.ArtFont(fmt.Sprintf("Hello %s !", kt.Name()))
            return nil
        })),
    )   

    if err := app.Run(); err != nil {
        log.Println("run service fail", err.Error())
    }
}


func RegisterServer(c config.Config, hs *http.Server, gs *grpc.Server) {
    cfg := &conf.Config{}
	// 配置监听变更
    c.ScanWatch("business", func(value config.Value) {
        if err := value.Scan(cfg); err != nil {
            log.Error("business 配置变更失败:" + err.Error())
        } else {    
			log.Info("business 配置变更成功")
        }
    })
    
    srv := service.New(cfg)
    v1.RegisterClientServer(gs, srv)
}

```

#### 从配置文件中初始化服务
```go
import (
    // 引入配置中心sdk
	"github.com/limes-cloud/configure/client"
)

func main() {
    app := kratosx.New(
    	// 使用配置中心初始化
        kratosx.Config(client.NewFromEnv()),
        // 注册服务
        kratosx.RegistrarServer(RegisterServer),
		// 启动之后打印启动信息
        kratosx.Options(kratos.AfterStart(func(ctx context.Context) error {
            kt := kratosx.MustContext(ctx)
            pt.ArtFont(fmt.Sprintf("Hello %s !", kt.Name()))
            return nil
        })),
    )   

    if err := app.Run(); err != nil {
        log.Println("run service fail", err.Error())
    }
}

func RegisterServer(c config.Config, hs *http.Server, gs *grpc.Server) {
    cfg := &conf.Config{}
    // 配置监听变更
    c.ScanWatch("business", func(value config.Value) {
        if err := value.Scan(cfg); err != nil {
            log.Error("business 配置变更失败:" + err.Error())
        } else {
            log.Info("business 配置变更成功")
        }
    })
    
    srv := service.New(cfg)
    v1.RegisterClientServer(gs, srv)
}
```
