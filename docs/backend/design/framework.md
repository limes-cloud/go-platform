本文档介绍了在项目中如何使用DDD领域驱动模式进行开发，在开始之前，我想你应该具有一定的DDD领域驱动开发的知识，如果没有也没关系，你只需要记住，我在后续的过程中在每个目录的描述下，你应该怎么做即可。

## 什么是DDD领域驱动设计模式？
领域驱动设计（Domain-Driven Design, DDD）是一种旨在解决复杂业务需求的软件架构方法。该方法采用分而治之的策略，通过详细地分析业务领域、建立精确的模型，并据此指导微服务的实现，以便更有效地应对业务的复杂性并提升系统的可维护性。DDD的核心流程可分为两大部分：战略设计和战术实施。战略设计涉及业务流程的深入理解、业务领域的划分、模型的构建以及服务的抽象；而战术实施则涉及将这些领域的概念转换为具体的、可执行的服务代码。

在Go语言的微服务架构中，DDD可以通过以下四个层次的结构来实现：接口层（负责与外界交互）、应用层（处理参数校验、处理顶层业务逻辑）、领域层（包含实体、值对象、聚合根、业务领域模型）、基础设施层（提供技术支持如数据库访问）。在实施DDD时，要特别留心避免一些常见的反模式，例如忽视对业务的深入分析、过度设计以及不合理的上下文界限划分等问题。

DDD领域设计模式需要开发人员熟练掌握其思想，对业务模型足够熟悉，但是很多情况下，我们在开发项目时所面对的业务都是未知的，随着时间的变更，业务不断的变更迭代，如果要完全遵循DDD理念进行设计在团队项目中得保证每个成员都和你一样具有同等的开发、业务理解能力，这显然是不太可能的。

## 没有完美的DDD设计模式
实际上并没有100%理想的DDD设计模式， 过度的遵循DDD领域驱动设计模式只要让项目显得跟花里胡哨，性能会成为设计模式的牺牲品，最简单的例子就是 req->vo->ent->po->ent->vo->reply。每一层的转换都需要转换具体的操作对象，单个对象还好，遇到请求列表的时候，这简直就是灾难，相信你在很多的DDD示例中也看见过很多在获取数据后，通过for遍历转换对象的操作吧。

在后续的目录规划上，并不是100%遵循DDD领域驱动理念进行设计的，为了减少复杂度、减少性能牺牲而去破坏了一些理论完整性，但是我会在后面的规划中详细描述为什么要这么做，这么做的好处是什么。


## 目录概览
```
├── api # 接口层
│   └── layout # layot服务定义
│       ├── dictionary # 应用定义。
│       │   └── v1
│       └── errors # 系统全局error
├── cmd # 入口
│   └── server 
├── internal
│   ├── app # 应用层
│   ├── conf # 配置文件 
│   ├── domain # 领域层
│   │   ├── entity # 实体
│   │   ├── repository # 仓储接口
│   │   └── service # 领域服务
│   ├── infra # 基础设施层
│   │   ├── dbs # 数据库基础设施
│   │   ├── mqs # 消息队列基础设施
│   │   └── rds # 缓存基础设施
│   └── types # 值对象
├── static # 静态文件
├── third_party # 三方proto
└── tmp # 临时日志文件
```

### api目录
```
├── api # 接口层
│   └── layout # layot服务定义
│       ├── dictionary # 应用定义。
│       │   └── v1
│       └── errors # 系统全局error
│   └── ... # 其他服务
```
api目录相当于DDD中的接口层，我们在proto中可以直接定义请求参数、返回参数、接口等，并生成service\client。api目录下并不是直接就存放当前系统的proto,而是增加了一层目录结构进行存放，这样的好处时我们可以将当前系统的proto单独抽出去作为大仓模式，也可以引入额外三方的服务的proto生成对应的client代码。


### cmd目录
cmd 目录是启动目录，里面主要是实现了配置的初始化和变更监听，完成了将应用层注册到接口层中。

### internal目录
internal目录主要存放项目内部的核心逻辑代码，不希望能被外部访问引用的代码，比如我当前项目的配置文件、我当前服务的具体业务逻辑等。

为什么要引入internal? 什么时候不需要引入internal? 这其实是大家比较困惑的问题。假如我开发了一个服务是用户中心，属于一个中台服务，很多的外围服务需要通过我来获取用户信息，最理想的情况下是所有的外围服务直接引用我的api中的proto自主进行生成对应的client代码，但是我们想想，用户中心既然为一个中台服务，为什么我不能直接调用用户中心已经通过proto生成的client代码呢（当然这需要外围服务也是使用Golang进行开发的），所以这就造成了一些业务上的代码对外进行了泄漏，因为业务逻辑的变动是必然的，不要因此造成外围服务的一些错误使用。

这里肯定又有人问了，那如果proto也变动了怎么办，两边版本不一致怎么办？其实这个问题很好理解， 实际上我们开发的时候接口的入参和出参是很少进行变动的，即使变动那也要遵循向下兼容原则。即使你不用proto，直接使用接口请求，难道直接变更用户信息字段就不会对下游产生影响了么？我string变int就合理了吗？如果我仅仅是新增字段，即使版本不一致那也毫无影响，对于下游来将，只要当前的返回的字段能够满足业务要求即可，当下游业务需要使用到我新增的字段，那就主动更新版本即可。 即使你直接使用api请求，上游新增字段是，你不也得改对应的代码新增字段来承接解析上游返回的数据，不是么。


#### internal/conf
主要负责整个内部系统的配置文件，和kratos不一样的是，我采用的是结构体直接定义，而不是使用protoc定义，这样在很大程度上，会更加方便在开发的过程中进行使用。

另外需要注意的是conf定义在internal内是为了防止第三方服务在引用当前服务时，调用到其配置文件。

还有就是conf配置应该被看作是一个基础设施层，伴随着服务的初始化进行注入使用。

#### internal/app
app目录充当着系统的应用层，主要负责协议转换（DTO）、参数校验、以及领域编排等。应用层不应该包含业务逻辑，而是进入核心业务逻辑之前的一些准入工作，以及核心逻辑处理完成之后的收尾。

比较基础的表现形式如下：
```go
func (s *DictionaryApplication) ListDictionary(c context.Context, req *pb.ListDictionaryRequest) (*pb.ListDictionaryReply, error) {
	ctx := kratosx.MustContext(c)
	// dto 转换
	in := &types.ListDictionaryRequest{
        Page:     req.Page,
        PageSize: req.PageSize,
        Order:    req.Order,
        OrderBy:  req.OrderBy,
        Keyword:  req.Keyword,
        Name:     req.Name,
	}
	// 领域编排
	result, total, err := s.srv.ListDictionary(ctx, in)
	if err != nil {
		return nil, err
	}

	// 结果收尾
	reply := pb.ListDictionaryReply{Total: total}
	if err = valx.Transform(result, &reply.List); err != nil {
		ctx.Logger().Warnw("msg", "reply transform err", "err", err.Error())
		return nil, errors.TransformError()
	}

	return &reply, nil
}
```
这里面引入了一个types,你可以将它理解层值对象。

#### internal/types目录
types目录充当着值对象的角色，但是又不是完全是值对象，其实我们在使用proto进行定义的时候，proto中定义的结构也可以是被看作值对象的，但是proto始终是接口层的东西，而proto在大多数公司来说都会被存放在外部仓库中，如果业务强依赖接口层的proto，显然不是一个明智的选择，所以这里新增了types目录，主要是存放了一些必须的请求的参数，和返回参数。

当然不是所有的请求参数、返回参数都需要存放到types中，那怎样的数据需要存放到types目录呢？我们看以下的示例：

我想查询用户的分页数据，参数为page、pageSize。这个要求其实很简单了，这种其实我们就没必要再定义对应的请求参数，因为只有两个参数，我们直接将这两个数据作为函数的参数往下传递即可。最终基础设施层，操作数据库
``` 
func (ObjectInfra) ListUser(page int,pageSize int) ([]*User,int64,error){
// some code
// db.xxxx
}
```

那比如你有一个查询列表的方法，我的基础设施层需要根据你的条件进行查询，比如我想实现一个查询指定分页、够根据我选择的字段排序、也具有通过Name进行查询的功能。那么最终你的请求参数大概是如下：
``` 
type ListDictionaryRequest struct {
	Page     uint32  `json:"page"`
	PageSize uint32  `json:"pageSize"`
	Order    *string `json:"order"`
	OrderBy  *string `json:"orderBy"`
	Name     *string `json:"name"`
}
```
很显然，通过参数展开传递是一个非常不明智的行为，而是直接传递整个结构体，所以这种情况下，需要你在types中添加对应的结构定义。

### internal/infra
实现仓储接口，RPC 具体实现、DB 存储、缓存、消息中间件等，都会去实现领域层定义好的仓储接口。

这里有一个细节我想可以值的提及以下，就是基础设施层我们在初始化的时候，应该返回该结构的引用，而不是返回repo的接口。

``` 
type DictionaryInfra struct {
	// db 基础设施中间件
}

// 直接返回结构定义
func NewDictionaryInfra() *DictionaryInfra {
	return &DictionaryInfra{}
}

// 返回接口定义
func NewDictionaryInfra() repository.DictionaryRepository {
	return &DictionaryInfra{}
}

```

为什么不提倡返回对应的repo接口呢？ 我们在领域服务中基本上会调用repo接口进行业务编排，但是有时候我们在开发的过程中，我们一个领域服务经常会使用到多个repo接口，比我我在实现用户的对应的逻辑时，需要查询角色信息，使用角色的repo，那么用户领域服务的结构大概如下。
``` 
type UserService struct{
    userRepo repository.UserRepository 
    roleRepo repository.RoleRepository 
}
```
但是这里我仅仅是只用到了查询当前用户的角色这一个功能，而引入整个repository.RoleRepository。RoleRepository中还包含有角色的创建、删除、修改，这是我根本用不上的。所以说，我们在初始化基础设施层时大可不必直接返回对应的repo，而是返回结构体应用，具体的业务代码里面更具需要去定义接口，更加清晰的划定业务界限。



#### internal/domain目录
领域服务核心能力，提供业务逻辑实现（比如数据生成读取、报表下载、GMV 等)，核心要素包括领域服务 service 、领域实体 entity、仓储接口 repository。其中业务缓存、分布式锁、发送通知等，尽量可以收敛到领域服务之中。


#### internal/domain/entity目录
entity是定义系统的实体的，在标准的DDD概念中，实体并不是基础设施层直接操作的对象，而是需要将实体转换成PO，这里其实我并不建议这么做，主要是这样的转换造成了大量的性能丢失，每次的查询时，从DB中取出数据了之后，都要进行转换赋值。

在很多的示例中，相信你都会看见如下的类似的代码。
``` 
func (r dictionaryRepo) ListDictionary(ctx kratosx.Context, req *types.ListDictionaryRequest) ([]*entity.Dictionary, uint32, error) {
	// some code 
	// 查询po 将po转换为entity
	for _, m := range ms {
		es = append(es, r.ToDictionaryEntity(m))
	}
	return es, uint32(total), nil
}
```

还有就是在DDD说明了实体是一个完整的个体，实体和实体之间的相互引用需要使用聚合根，这里的聚合根是什么？说白了就是一个更大的结构体，包含了相互引用的实体。

这样的做法肯定是最好的，那为什么在我的项目目录中并没有聚合根这个目录呢？

聚合根很多人没办法进行良好的的划分、设计，本来是一个解决问题的设计，最终反而因为设计、划分不合理，造成项目反而更加不可维护。当然这只是一部分，另外一部分原因是我们在开发过程中，更多的会使用一些orm框架，或者使用一些关联查询等，这已经破坏了实体的完整性。

比如我要查询用户以及用户的角色信息，在聚合根中的话，会先查询用户信息，在根据用户信息查询角色信息。最终聚合到一起。经常写代码的同学都知道，这种我们会更偏向户去书写一些关联查询的代码，在查询用户的同时，在基础设施层就直接查询出对应的角色信息了，这在性能方面来说，明显是更高效的。

所以我并不建议使用聚合根，即使在设计上，他是最合理的。


#### internal/domain/repository目录
repository目录定义了具体的领域服务中需要操作的基础设施层的接口实现。

#### internal/domain/service目录
service目录是领域服务目录，主要负责核心逻辑。除此之外值的一提的是出了核心逻辑之外，包含分布式锁、缓存、mq等都应该放到该层。

### internal/pkg
主要负责内部系统的一些方法包封装，这里放到internal下时为了防止外部调用。

### static
主要存放系统的一些静态资源文件

### third_party
主要存放三方的protoc文件

### tmp
主要存放临时文件，如日志等


## 总结
最后我还强调说明，并没有完美的设计模式，我们在性能和设计模式上可以自行进行取舍。当然至少在Go开发上，相信你肯定是更在乎其性能的，不必要为了设计而设计，最终却本末倒置了。如何在设计和性能上达到一个平衡点，在既可以简化项目、又能保持性能这我认为是最佳的。