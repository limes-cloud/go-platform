config 配置组件是用来快速获取、监听配置的。使用config我们可以很轻松的在项目中管理配置、实时监听配置变更等。

context挂载的中间件默认都是依靠config组件来进行初始化的，所以我们只需要配置好config数据，即可开箱即用已经内置的中间件。
接下来会分别介绍每一个配置项的作用以及如何使用。
## 快速使用
```go
c := context.Background()
ctx := kratosx.MustContext(c)
// 获取配置组件
ctx.Config()
```

## 初始化监听配置
```go
c := context.Background()
ctx := kratosx.MustContext(c)
// 获取配置组件
ctx.Config().ScanWatch("business", func(value config.Value) {
// some code
})
```

## 获取系统配置
```go
c := context.Background()
ctx := kratosx.MustContext(c)
// 获取配置组件
sysconf := ctx.Config().App()
// some code
```

## 获取指定配置
```go
c := context.Background()
ctx := kratosx.MustContext(c)
// 获取配置组件
value,err := ctx.Config().Value("business.key").Float()
// some code
```

虽然使用Config Value可以很方便获取配置数据，但是这样也产生一个弊端，那就是获取配置的key需要我们人为的去书写，而在编译阶段无法感知这个key是否存在或者类型是否正确，这样就可能导致配置获取失败，产生error需要额外进行处理。
当然你也可以全局声明config
```go
type Config struct{
    // some field
}
cfg := Config{}
ctx.Config().Scan(&cfg)

// cfg 进行传递给后续使用
```
