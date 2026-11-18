## 组件说明
pool是一个通用的全局并发池，可以将系统中的并发进行有效的控制，防止滥用并发导致系统资源枯竭，并且提供了并发wait的能力，能够快速实现并发任务。

## 组件配置
yaml 配置
```yaml 
request: 
  enableLog: true
  retryCount: 3
  retryWaitTime: 3s
  maxRetryWaitTime: 3s
  timeout: 10s
  userAgent: "server name"
```

对应go结构体
```go
type App srruct{
	Request *Request `json:"request"`
}

type Request struct {
	EnableLog        bool          // 是否开启请求日志
	RetryCount       int           // 最大重试次数
	RetryWaitTime    time.Duration // 重试等待时间
	MaxRetryWaitTime time.Duration // 最大重试等待时间
	Timeout          time.Duration // 请求超时时间
	UserAgent        string        // 请求服务名称，UA
}
```

## 组件定义
```go
type Request interface {
	// DisableLog 禁用当前请求的日志
	DisableLog() Request

	// Option 设置请求数据
	Option(fn Func) Request

	// Get 发送get请求
	Get(url string) (*response, error)

	// Post 发送请求
	Post(url string, data any) (*response, error)

	// PostJson 发送json请求
	PostJson(url string, data any) (*response, error)

	// Put 发送json请求
	Put(url string, data any) (*response, error)

	// PutJson 发送json请求
	PutJson(url string, data any) (*response, error)

	// Delete 发送请求
	Delete(url string) (*response, error)

	// Do 执行请求
	Do() (*response, error)
}
```

## 使用方式

```go
// 基础使用
resp,err := ctx.Request().Get("https://baidu.com")

// 打印body
resp.Body()

// 解析到指定的结构体上
var data = struct{
	Code int `json:"code"`
	Data any `json:"data"`
}
resp.Result(&data)


// 设置请求header
resp, err := ctx.Request().Option(func(r *resty.Request) {
	r.Header.Set("test", "test")
}).Get("https://www.baidu.com")

```

