kratosx 是基于kratos 进行二次封装的基础库，里面实现了常用的一些工具的封装，在常规的kratos开发过程中，初始化一个系统需要编写很多的初始化、中间件的代码，而使用kratosx，你只需要简单的修改配置文件即可使用,并且kratosx是支持配置文件实时重载的，在很多时候我们修改了配置之后无需重新启动服务，即可生效。

kratosx 并不是新的框架，而是一个工具包，他是将kratos的一些常用的方法工具进行封装，从而简化了用户对于kratos的使用难度，比如我的项目中需要限流，需要数据库，需要缓存，其实这些常用的中间件在每个服务中都需要，但是我需要在每个服务中都去实现一遍他的初始化，这样不仅仅在服务中产生了很多冗余代码，还增加了维护成本。

为了抽离这些常用的中间件在每个服务中重复实现、维护的成本，所以开发了kratosx作为整个项目的基础库。

## 项目地址
[githun/kratosx](https://github.com/limes-cloud/kratosx)

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

	internalconf "github.com/go-kratos/kratos-layout/internal/conf"
	"github.com/go-kratos/kratos-layout/internal/service"
)

func main() {
	app := kratosx.New(
		// 指定启动配置
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
	conf := &internalconf.Config{}
	// 监听配置变动
	c.ScanWatch("business", func(value config.Value) {
		if err := value.Scan(conf); err != nil {
			log.Error("business 配置变更失败")
		} else {
			log.Error("business 配置变更成功")
		}
	})
    // 注册服务，这里是具体的注册业务的实现，根据你的业务来进行变动
	service.New(conf, hs, gs)
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
kratosx中的配置是兼容kratos的。我们可以通过kratosx.Config来指定配置初始来源。当然更建议使用配置中心进行统一管理。
配置中心是Go-Platform中自带的用于统一管理配置的服务，具体可阅读 ，在kratosx中我们可以使用以下方式快速接入配置中心。
```go
import (
    // 引入配置中心sdk
	"github.com/limes-cloud/configure/client"
)

func main() {
    app := kratosx.New(
    	// 使用配置中心初始化
        kratosx.Config(client.NewFromEnv()),
        // 当然你也可以使用其他的配置组件
        // 从指定的文件中加载配置
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
```

## Context
kratosx提供了很多的工具包都挂载到了kratosx.Context上，在使用kratosx进行启动项目之后，我们可以很方便的在项目中进行使用。
kratosx.Context 是一个实现了content.Content类型的接口，我们可以将kratosx.Context作为原来的ctx，往下进行传递。然后就可以使用kratosx中间件等。kratosx.Context具有原来ctx的全部能力，包括timeout cancel、value等。


```go
ctx := kratosx.MustContext(c)

ctx.DB() //使用数据库
ctx.Logger() //使用日志
ctx.Config() //使用配置
ctx.... 
```
为什么要使用kratosx.Context进行挂载？在go的开发过程中，使用ctx，在参数中进行传递已是一个很常见的开发习惯，因为我们可以用ctx做超时、并发、存储等工作。实际上我们在开发过程中会使用很多的中间件，这些中间件需要不断的暂用额外的参数进行传递，反而增加了参数的数量，使得代码可读性变得极差，ctx上下文既然是本来就需要进行携带传递的，那我们只要能够实现ctx对应的接口，再把常用的一些中间件挂载上去，这样既能减少参数，又能使得ctx保持原有的功能，何乐而不为呢。
```go
// SayHello implements SayHello
func (l *Logic) SayHello(ctx kratosx.Context, in *v1.HelloRequest) (*v1.HelloReply, error) {
	// 使用日志
	ctx.Logger().Infow("info", "say hello request")
	
	
	// ...
	return &v1.HelloReply{
		Message: l.conf.SayText + ":" + in.Name,
	}, nil
}
```
kratosx content的工具是和配置强相关的，我们可以通过配置来配置来初始化具体的工具包。接下来我们将针对每个工具包的配置以及具体的使用方法都展开进行详细说明。

## 服务配置
服务配置是配置服务的启动端口、请求超时控制、tls以及跨域等，主要分为http、grpc. 主要的配置如下项。
```yaml
env: TEST # 当前环境标识符配置
server:
  count: 3 #最大启动服务数量，当端口被占用时，自动寻找可用端口
  registry: consul://127.0.0.1:8500?datacenter=dc #服务注册地址，自动注册
  tls: #是否开启tls链接加密
    name: www.qlime.cn # 证书域名 
    ca: xxx #证书内容
    pem: xxx #证书内容
    key: xxx #证书内容
  http: #http配置
    host: 0.0.0.0 #地址
    port: 6081 #端口
    timeout: 5s #超时时间
    cors: #跨域配置
      allowCredentials: true
      allowOrigins: [ "*" ]
      allowMethods: [ "GET","POST","PUT","DELETE","OPTIONS" ]
      allowHeaders: ["Content-Type", "Content-Length", "Authorization"]
      exposeHeaders: ["Content-Length", "Access-Control-Allow-Headers"]
    marshal: #序列化配置
      emitUnpopulated: true #是否不忽略默认值
      useProtoNames: true #是否使用protoc的名字作为字段key
    formatResponse: true #是否格式化输出
    pprof: #pprof分析工具
      query: password
      secret: limes-cloud
  grpc: #grpc配置
    host: 0.0.0.0 #地址
    port: 6071 #端口
    timeout: 5s #超时时间
```
获取当前环境标识
``` 
ctx := kratosx.MustContext(c)
ctx.Env()
```

## 日志配置
```yaml
log:
  level: 0 #日志输出等级 -1:debug 0:info 1:warn 2:error 
  caller: true #是否显示打印代码行
  enCoder: console #日志打印格式，console/json 默认为json
  output: #日志输出方式
    - stdout # stdout:控制台输出，k8s日志收集
    - file # file:输出到文件
  file: #output存在file时此配置才可生效
    name: ./tmp/runtime/output.log #日志存放地址
    maxSize: 1 #日志文件最大容量,单位m
    maxBackup: 5 #日志文件最多保存个数
    maxAge: 1 #保留就文件的最大天数,单位天
    compress: false #是否进行压缩归档
```
使用配置
```go
ctx := kratosx.MustContext(c)
ctx.Logger().Info("info", "say hello request")
ctx.Logger().Warn("info", "say hello request")
...
```

## 数据库配置
```yaml
database:
  system: #数据库实例名称,如有多个数据库可新增
    enable: true #是否启用数据库
    drive: mysql #数据库类型 可选mysql/postgresql/sqlServer/tidb/clickhouse
    autoCreate: true #是否自动创建数据库
    connect: #数据库连接信息
      username: root #账号
      password: root #密码
      host: 127.0.0.1 #host
      port: 3306 #端口
      dbName: configure_test #数据库名称，当不存在时且配置autoCreate会进行自动创建
      option: ?charset=utf8mb4&parseTime=True&loc=Local #扩展信息
    config: #数据库配置信息
      initializer: #自动初始化
        enable: true #是否启动自动初始化
        path: deploy/data.sql #自动初始化的sql
      transformError: #错误格式化
        enable: true #是否开启
        format: #自定义格式化配置
          duplicatedKeyFormat: "" # {table}中已存在{column}:"{value}"
          addForeignKeyFormat: "" # {table}中不存在{column}:"{value}"
          delForeignKeyFormat: "" # {table}中正在使用{column}:"{value}"
      maxLifetime: 2h #最大生存时间
      maxOpenConn: 20 #最大连接数量
      maxIdleConn: 10 #最大空闲数量
      logLevel: 4 #日志等级 4:info 3:warn 2:error 1:silent
      slowThreshold: 2s #慢sql阈值
      prepareStmt: false # 是否创建prepared statement
      dryRun: false # 生成 SQL 但不执行
      tablePrefix: "" #数据表前缀
```
使用数据库（目前已经支持mysql、pg、tidb、clickhouse）
```go
ctx := kratosx.MustContext(c)

// 只存在一个数据库配置时，获取数据库实例
ctx.DB()

// 存在多个数据库配置时，获取数据库实例
ctx.DB("dbKey")
```
错误格式化是什么，具体有什么用？

错误格式化是用来进行优雅的错误提示用的，在我们的开发过程中，会经常遇到插入数据，遇到唯一索引导致出错的问题。为了解决这个问题，我们一般情况下会先对唯一列进行查询，然后在进行插入。

```go
type User struct {
	types.BaseModel
	Name  string `json:"name" gorm:"not null;size:32;comment:用户姓名"`
	Phone string `json:"phone" gorm:"unique;not null;size:11;comment:用户电话"`
}

func (u *User) Create(ctx kratosx.Context) error {
	db := ctx.DB()
	if err := db.Find(User{}, "phone=?", u.Phone).Error; err != nil {
		// 数据不存在则进行插入
        if errors.Is(err, gorm.ErrRecordNotFound) {
			return ctx.DB().Create(u).Error
		}
		return err
	}
    // 存在则返回错误提示
	return errors.New("用户电话已存在：" + u.Phone)
}
```
而现在通过错误格式化，你只需要进行如下这样编写，错误格式化插件会自动识别错误信息将错误信息进行转换。假如当前的手机号已经被使用，则error信息为： "用户信息中已存在用户电话:xxxxxxx"
```go
func (u *User) Create(ctx kratosx.Context) error {
	return ctx.DB().Create(u).Error
}
``` 

如何跨方法使用事务
```go
ctx := kratosx.MustContext(c)
ctx.Transaction(func(ctx kratosx.Context) error {
    id, err := u.repo.Create(ctx, user)
    if err != nil {
    return err
    }
    // some code 
    // return nil 事务正常提交
    // return err 事务回滚
    return nil
})
```

## Redis配置
``` yaml
redis:
  catch: #redis实例名称,如有多个redis可新增
    enable: false #是否启用redis
    host: 127.0.0.1:6379 #redis地址
    username:  #连接账号
    password:  #连接密码
```
redis使用
```go
ctx := kratosx.MustContext(c)

// 只存在一个redis配置时，获取数据库实例
ctx.Redis()

// 存在多个redis配置时，获取数据库实例
ctx.Redis("redisKey")
```

## 身份鉴权
JWT（JSON WEB TOKEN）：JSON网络令牌，JWT是一个轻便的安全跨平台传输格式，定义了一个紧凑的自包含的方式在不同实体之间安全传输信息（JSON格式）。它是在Web环境下两个实体之间传输数据的一项标准。实际上传输的就是一个字符串。广义上讲JWT是一个标准的名称；狭义上JWT指的就是用来传递的那个token字符串。
```yaml
jwt:
  enableGrpc: bool #是否对grpc启动鉴权，不建议开启
  redis: cache  #redis实例名称，使用唯一登录/黑名单时为必填项
  secret: limes-cloud-test #密钥
  unique: true #是否开启唯一账号登录,开启此项必须设置redis
  uniqueKey: uid #唯一账号登录的数据下标，主要是用来取生成token时的key
  expire: 2h #过期时间
  renewal: 180s #续期时间
  whitelist: #忽略token校验以及鉴权的白名单 http 方法名:path  grpc GRPC:operation
    POST:/configure/v1/login: true  # 登录
    POST:/configure/v1/logout: true  # 登录
    POST:/configure/v1/token/refresh: true # 刷新
    *:/configure/v1/*: true #通配符白名单
```
jwt使用以及接口定义
```go
ctx := kratosx.MustContext(c)

ctx.JWT()

// jwt接口定义
type Jwt interface {
    // 生成token
    NewToken(m map[string]any) (string, error)
    // 解析token到dst
    Parse(ctx context.Context, dst any) error
    // 解析token为map
    ParseMapClaims(ctx context.Context) (map[string]any, error)
    // 是否为白名单
    IsWhitelist(path string) bool
    // 是否为黑名单
    IsBlacklist(token string) bool
    // 添加黑名单
    AddBlacklist(token string)
    // 从ctx中获取token
    GetToken(ctx context.Context) string
	// 设置token到ctx
    SetToken(ctx context.Context, token string) context.Context
    // token续期
    Renewal(ctx context.Context) (string, error)
    // 对比token是否为当前登录的token
    CompareUniqueToken(key, token string) bool
}
```

##  资源鉴权
 资源鉴权一般是和JWT搭配一起使用的，jwt主要是用来进行身份鉴权，就是识别你当前的token是否是我的系统能识别的token,以及从token信息中取出用户信息，而资源鉴权则是对用户的行为进行管控，比如用户只能查看数据不能删除数据，用户只拥有一部分功能杰接口权限管控等。
```yaml
authentication: #鉴权配置
  db: system  #数据库实例名称
  redis: cache #redis实例名称
  roleKey: role_keyword #角色下标标识，设置token时data下标
  skipRole: #需要跳过的角色
    - superAdmin
  whitelist: # 需要跳过鉴权的接口
    POST:/configure/v1/login: true  # 登录
    POST:/configure/v1/logout: true  # 登录
    POST:/configure/v1/token/refresh: true # 刷新
```

资源鉴权使用
```go
ctx := kratosx.MustContext(c)
ctx.Authentication()

// ctx.Authentication() 返回接口定义
type Authentication interface {
    // 添加白名单
    AddWhitelist(path string, method string)
    // 删除白名单
    RemoveWhitelist(path, method string)
    // 是否为白名单
    IsWhitelist(path string, method string) bool
    // 鉴权
    Auth(role, path, method string) bool
    // 获取角色
    GetRole(ctx context.Context) (string, error)
    // 返回rbac实例
    Enforce() *casbin.Enforcer
    // 是否为跳过的角色
    IsSkipRole(role string) bool
}
```

## 服务鉴权
服务鉴权是在分布式架构下，来判断哪些服务是有请求权限的。防止直接通过内网多某个服务进行请求。
```yaml
signature:
  enable: true
  ak: limeschool
  sk: helloworld
  expire: 10s
  whitelist:
    GET:/configure/v1/list: true  
```

## 并发池
```yaml
pool: #并发池配置
  size: 10000 #最大协程数量
  expiryDuration: 30s #过期时间
  preAlloc: true #是否预分配
  maxBlockingTasks: 1000 #最大的并发任务
  nonblocking: true #设置为true时maxBlockingTasks将失效，不限制并发任务
```
并发池使用。
```go
ctx := kratosx.MustContext(c)

ctx.Go(pool.AddRunner(func() error {
    // some code
    return nil
}))
```

## 邮箱配置
```yaml
email: # 邮件发送相关配置
  template: #邮件模板
    captcha:  #邮件模板名称
      subject: 验证码发送通知 #邮件模板主题
      path: static/template/email/default.html #邮件模板路径
      from: xxx@qq.com
      type: "text/html" #文本内容格式
  user: xxx@qq.com #发送者
  name: xxx公司 #发送着名称
  host: smtp.qq.com:25 #发送host
  port: 25 #发送着端口
  password: xxxx # 发送host密码
```
邮箱使用
```go
ctx := kratosx.MustContext(c)
ctx.Email().Template("模板名称").Send("接受者邮箱", "接受者姓名", map[string]any{
    "answer": "xxxx", //模板变量
    "ssss":   "xxx",
})

ctx.Email().Template("captcha").Send("1280291001@qq.com", "方先生", map[string]any{
    "answer": "xxxx",
    "ssss":   "xxx",
})
```

## 验证码
```yaml
captcha: #验证码配置
  login: #验证码实例
    type: image  #验证码类型，主要分为 image/email
    length: 6    #验证码长度
    expire: 180s #过期时间
    redis: cache #redis实例
    refresh: true #是否允许刷新
    height: 80   #图片高度
    width: 240	 #图片宽度
    skew: 0.7		 #偏斜率
    dotCount: 80 #点混合数量
  changePassword:
    type: email  #验证码类型
    length: 6    #验证码长度
    expire: 180s #过期时间
    redis: cache #redis实例
    template: captcha #邮箱模板名称
    refresh: true #是否可刷新，有效期内不能再刷新
    ipLimit: 10 #单个ip每日最多请求次数
```
验证码使用
```go
ctx := kratosx.MustContext(c)
ctx.Captcha()

ctx.Captcha() 返回接口定义
type Captcha interface {
    // 邮件验证码 tp:实例名称，ip:客户端ip,to:接收者邮箱
	Email(tp string, ip string, to string) (Response, error)
    // 图片验证码
	Image(tp string, ip string) (Response, error)
    // 验证邮箱
	VerifyEmail(tp, ip, id, answer string) error
    // 验证图片
	VerifyImage(tp, ip, id, answer string) error
}

Response 返回定义
type Response interface {
	ID() string
	Expire() time.Duration
	Base64String() string
}
```

## 请求日志
请求日志会打印请求的参数、以及返回的数据，方便问题排查
```yaml
logging: #请求日志配置
  enable: true #是否开启请求日志配置
  whitelist: #日志白名单，白名单内的将不会打印
    GET:/configure/v1/list: true  
```

## 链路追踪
链路追踪（Trace）是一种用于追踪分布式应用系统中请求处理过程的技术。它可以记录请求经过的所有服务节点和处理时间，帮助开发者快速定位和解决系统中的问题，如性能问题、错误和异常等
```yaml
tracing:
	httpEndpoint: localhost:4442 #采集地址
	sampleRatio: 0.8 #采集比例
	timeout: 10s #上报超时时间
	insecure: false
```

## 服务监控
```yaml
metrics: true
```

## 资源加载
资源加载器是用来加载一些常用的文件的，比如公私密钥等，通过文件加载器可以快速加载到内存，而不需要进行重新读取。
```yaml
loader:
  login: static/cert/login.pem
```
如何使用
```go
ctx := kratosx.MustContext(c)
ctx.Loader('关键字名称')
```

## 自适应限流
```yaml
rateLimit: true #是否开启自适应限流
```

## GRPC客户端配置
```yaml
client:
  - server: UserCenter #服务名称
    type: direct #服务类型 discovery/direct
    tls: #是否开启tls链接加密
      name: www.qlime.cn # 证书域名 
      ca: xxx #证书内容
      pem: xxx #证书内容
      key: xxx #证书内容
    signature: # 服务签名鉴权
     ak: limeschool
     sk: helloworld
    metadata: #请求服务携带元数据
      key: value 
    backends: #当服务类型为direct时,backends生效。
      - target: direct://127.0.0.1:8004 #目标地址direct://ip:port
        weight: 10 #权重
      - target: direct://127.0.0.1:8005
        weight: 10
```
使用方式
```go
ctx := kratosx.MustContext(c)
// 获取指定服务的连接句柄 
conn,err := ctx.GrpcConn("UserCenter")
if err!=nil{
    return nil,err 
}
// 使用连接句柄初始化客户端
userpb.NewServiceClient(conn)
```

## Http请求配置
我们在开发的过程中，经常需要去请求第三方的接口，这些接口可能不想我们使用kratos开发的,具有client-sdk。而是需要我们直接发起http请求从而自己进行解析，虽然发起http请求很简单，但是如果我们要要求具有错误重试，重试需要一定的等待时间，在请求的过程中需要打印请求参数，返回参数日志，是不是这一些列的要求，使得本身看似简单的功能也变得不简单了。kratosx提供了这样一个工具，你可以很方便的进行配置使用
```yaml
http:
  enableLog: true #是否开启日志
  retryCount: 3 #最大重试次数
  retryWaitTime: 10ms #等待时长
  maxRetryWaitTime: 1s #最大等待时长
  timeout: 60s #超时时间
```
使用方法以及接口定义
```go
ctx := kratosx.MustContext(c)
ctx.Http()

type Request interface {
    //禁用日志
    DisableLog() Request
    //其他可选配置 
    Option(fn RequestFunc) Request 
    //Get请求
    Get(url string) (*response, error) 
    // Post请求
    Post(url string, data any) (*response, error)
    //Post json请求
    PostJson(url string, data any) (*response, error)
    //Put 请求
    Put(url string, data any) (*response, error)
    //Put json请求
    PutJson(url string, data any) (*response, error)
    //delete请求
    Delete(url string) (*response, error)
}
```