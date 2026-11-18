## 组件说明
logger 组件是用来打印系统中的执行日志的。在系统中用来排查问题，尤为重要。

## 组件配置
yaml 配置
```yaml 
logger:
  level: 0
  output:
    - stdout
    - file
  file:
	errorAlone: true
    name: ./tmp/runtime/output.log
    splitTime: 1
    maxBackup: 5
    maxAge: 1
```

对应go结构体
```go
type App srruct{
	Logger *Logger `json:"logger"`
}

type Logger struct {
	Level      int8        `json:"level"`      // 日志等级 0：info 1:warning 2:error
	Output     []string    `json:"output"`     // 输出位置，支持 stdout,file
	EnCoder    string      `json:"enCoder"`    // 编码器类型 json,console，默认json
	Caller     bool        `json:"caller"`     // 显示调用者信息，默认不显示
	CallerSkip int         `json:"callerSkip"` // 调用者层级，默认2
	File       *LoggerFile `json:"file"`       // 日志文件配置
}

type LoggerFile struct {
	ErrorAlone bool          `json:"errorAlone"` // 错误日志单独输出
	Name       string        `json:"name"`       // 日志文件名
	SplitTime  time.Duration `json:"splitTime"`  // 日志切割时间间隔
	MaxAge     time.Duration `json:"maxAge"`     // 备份文件最大保存时间
	MaxBackup  int           `json:"maxBackup"`  // 备份文件最大个数，MaxAge可能仍会导致它们被删除。
}
```

## 组件定义
```
type Logger interface {
	// Info 日志
	Info(msg string, fs ...Field)

	// Warn 日志
	Warn(msg string, fs ...Field)

	// Error 日志
	Error(msg string, fs ...Field)

	// Sync 同步日志，无需主动调用，内部已在系统关闭的时候自动调用
	Sync() error
}
```

## 使用方式
打印日志
```
# 打印基础日志
ctx.Logger().Info("xxx",logger.F("key","value"))

# 打印告警日志
ctx.Logger().Warn("xxx",logger.F("key","value"))

# 打印错误日志
ctx.Logger().Error("xxx",logger.F("key","value"))
```

## 相关建议
在设计过程中，将日志等级收敛为`Info`、`Warn`、`Error`三类，其中`Info`适合打印一些正常的业务信息日志。`Warn`适合答应一些告警日志，它代表着系统的一些异常信息，但是不足以影响业务流程，比如慢SQL、参数校验失败等等，有错误，但是不足以影响业务的，可以使用`Warn`，而`Error`则是偏向于系统的严重错误，影响业务的某个业务直接运行的，后续我们可以直接通过Error的监听，实现一些error日志实时上报。