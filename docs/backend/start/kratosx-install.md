
kratos cli 的主要功能是进行创建项目、proto代码生成grpc、http、error代码。此cli工具在kratos原cli工具上做了一些调整和功能的增加，你可以使用kratos cli更加如鱼得水的开发你的项目。

## 安装
```shell
go install github.com/limes-cloud/kratosx/cmd/kratosx@latest &&\
go install github.com/limes-cloud/kratosx/cmd/protoc-gen-go-httpx@latest &&\
go install github.com/limes-cloud/kratosx/cmd/protoc-gen-go-errorsx@latest &&\
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest &&\
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest &&\
go install github.com/google/gnostic/cmd/protoc-gen-openapi@latest &&\
go install github.com/envoyproxy/protoc-gen-validate@latest
```
验证是否完成安装
```shell
 kratosx -v
```

## 创建项目
```shell
# kratosx new [项目名]
kratosx new helloworld
```

使用 `-r` 指定源
```shell
# 拉取kratosx layout模板
kratosx new helloworld -r https://github.com/limes-cloud/kratos-layout.git

# 拉取kratos layout模板
kratosx new helloworld -r https://github.com/go-kratos/kratos-layout.git

# 亦可使用自定义的模板
kratosx new helloworld -r xxx-layout.git
```

使用 `-b` 指定分支

```shell
kratosx new helloworld -b main
```

使用 `--nomod` 添加服务，共用 `go.mod` ，大仓模式
```shell
kratosx new helloworld
cd helloworld
kratosx new app/user --nomod
```

## 生成 Proto 代码
kratosx 支持service定义和message定义分离。
```shell
kratosx proto client api/helloworld/v1/demo.proto
```

## 生成后端一键 CURD 代码
kratosx 支持生成一键curd代码生成，具体代码说明参考layout项目中autocode/dictionary.json
```shell
kratosx autocode autocode/dictionary.json
```
todo: 支持前端生成、AI生成能力接入