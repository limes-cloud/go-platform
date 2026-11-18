## 组件说明
pool是一个通用的全局并发池，可以将系统中的并发进行有效的控制，防止滥用并发导致系统资源枯竭，并且提供了并发wait的能力，能够快速实现并发任务。

## 组件配置
yaml 配置
```yaml 
pool: 
  size: 10000
  expiryDuration: 30s #过期时间
  preAlloc: true #是否预分配
  maxBlockingTasks: 1000 #最大的并发任务
  nonblocking: true #设置为true时maxBlockingTasks将失效，不限制并发任务
```

对应go结构体
```go
type App srruct{
	Pool *Pool `json:"pool"`
}

type Pool struct {
	// 协程池大小
	Size             int 
	// 清理协程的扫描周期。清理协程会每隔 ExpiryDuration 时间扫描一次所有 worker，并清除那些未被使用超过 ExpiryDuration 的 worker
	ExpiryDuration   time.Duration
	// 初始化协程池时是否预分配内存。若为 true，池会提前分配内存以减少运行时的动态分配开销。
	PreAlloc         bool
	// 限制通过 pool.Submit 提交任务时，最多允许阻塞的 goroutine 数量。若超过此限制，提交任务会返回错误。
	MaxBlockingTasks int
	// 若为 true，则 pool.Submit 永远不会阻塞。若任务无法立即提交（如无空闲 worker 且池已满），会直接返回 ErrPoolOverload 错误
	Nonblocking      bool
}
```

## 组件定义
```go
type Pool interface {
	// WithContext 返回一个上下文
	WithContext(ctx context.Context) Pool

	// Go 执行任务
	Go(runner Runner) error

	// GoFunc 执行函数任务
	GoFunc(fn func()) error

	// NewWaitRunner 创建等待协程任务
	NewWaitRunner(opts ...WaitRunnerOptionFunc) WaitRunner
}

type WaitRunner interface {
	// AddTasks 批量添加协程任务
	AddTasks(f ...func() error)

	// AddTask 添加协程任务
	AddTask(f func() error)

	// Wait 等待协程任务执行完成
	Wait() error

	// ErrorList 获取协程任务执行错误列表
	ErrorList() []error
}
```

## 使用方式

```go
// 基础使用
ctx.Pool().GoFunc(func(){
	fmt.Println("hello pool!")
})

// 等待并发池
runner := Instance().NewWaitRunner(
	// 最大并发数量
	WithMaxWaitRunnerOption(count),
	// 遇到错误是否中断，停止后续的任务
	WithErrorBreakOption(true),
	// 遇到错误最大的重试次数
	WithRetryCountOption(3),
	// 错误等待重试时间
	WithRetryWaitTimeOption(time.Second)

)

for i := 0; i < count; i++ {
	ind := i
	// 添加任务
	runner.AddTask(func() error {
		time.Sleep(1 * time.Second)
		if ind == count-1 {
			return fmt.Errorf("error index %d", ind)
		}
		return nil
	})
}

// 等地执行
_ = runner.Wait()
```

