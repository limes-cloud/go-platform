server主要是负责系统初始化对应的配置文件。包含了http以及grpc的初始化。

## 服务配置
服务配置是配置服务的启动端口、请求超时控制、tls以及跨域等，主要分为http、grpc. 主要的配置如下项。
```yaml
env: TEST # 当前环境标识符配置
server:
  count: 3 #最大启动服务数量，当端口被占用时，自动寻找可用端口
  registry: consul://127.0.0.1:8500?datacenter=dc #服务注册地址，自动注册
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

## 配置解读
#### 环境标识
在上述配置中env是用来标识当前环境的，我们可以使用以下方法快速获取
```go
ctx := kratosx.MustContext(context.Background())
ctx.Env()
// output TEST
```

#### 服务数量
server.count 是控制服务启动数量的，在微服务的架构下，我们一般会存在多节点的情况，针对于同一个系统来说配置文件都是固定的，那么在同一个主机上启动多节点的时候，会出现端口占用的情况，
server.count 是为了解决这个问题的，他可以控制服务的数量。比如我以上配置，http服务端口port为6081，server.count为3，那么这个服务的端口占用分别问6081、6082、6083.当启动多节点时会自动进行寻找可用的端口并启动。
同理grpc服务也是一样的。

#### 注册中心
注册中心是一个自动注册服务的配置，我们在启动多节点的时候，可以使用注册中心快速进行注册。目前已支持consul，后续会逐步支持其他中间件。

#### 输出格式化
server.http.formatResponse 是一个格式化输出的配置，默认情况下，http请求会直接输出数据
```json
{
  "total":0,
  "list":[]
}
```
启用formatResponse后

```json
{
  "code": 0,
  "data": {
    "total":0,
    "list":[]
  },
  "trace_id": ""
}
```
