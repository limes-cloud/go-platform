<div align=center>
<img src="https://limes-cloud.oss-cn-beijing.aliyuncs.com/go-platform.png" width=500" height="300" />
</div>
<div align=center>
<img src="https://img.shields.io/badge/golang-1.21-blue"/>
<img src="https://img.shields.io/badge/kratos-2.7.2-red"/>
<img src="https://img.shields.io/badge/vue-3.3.4-bright"/>
<img src="https://img.shields.io/badge/arco.design-4.52-orange"/>
<img src="https://img.shields.io/badge/uni.app-1.25.2-cyan"/>
<img src="https://img.shields.io/badge/uv.ui-1.19.1-bright"/>
</div>

### 预览地址
- 账号：1280291001@qq.com
- 密码：123456
- 地址：[立即进入](http://admin.qlime.cn)


### 文档地址
[Go-Platform 文档](https://www.yuque.com/limes-cloud/blvuyc)

### 项目背景
市面上的后台快速开发框架，例如若依等admin框架，通常只提供了后台管理端的开发支持，而缺乏对客户端（C端）业务的完善支持。在实际应用中，我们面临着一系列问题。

首先，将C端业务逻辑直接集成到后台管理端存在潜在的安全风险。这可能导致用户权限越级，进而危及整个管理端数据的安全性。

其次，二次开发这些admin框架时，需要深入理解并适应它们的项目代码逻辑。由于开发习惯和代码风格的不同，这可能导致不必要的困扰和适应期。

随着业务的不断增长，我们逐渐意识到所有服务都放在一个单一服务中是不合理的。业务的复杂化使得我们需要更灵活的解决方案，而这包括对服务的有效拆分。

在这一背景下，我们必须认识到随着业务的不断复杂化，单一服务的模式已经无法满足需求。因此，我们需要考虑服务的拆分，设计一个更合理的分布式架构，以应对多样化的业务需求。这不仅有助于提高系统的可维护性和扩展性，还能够降低潜在的风险，并更好地满足未来业务的发展和变化。通过合理的服务拆分，我们能够更好地管理和部署各个业务模块，使整个系统更加健壮和适应性强。


### 技术选型
##### 开发框架
- 前端：使用字节 [Arco中后台最佳实践框架](https://arco.design/vue/docs/theme)进行开发
- 后端：使用B站 [Kratos一套轻量级 Go 微服务框架](https://github.com/go-kratos/kratos)进行开发
- 缓存：redis
- 数据库：mysql

项目支持单台服务器以及k8s集群。

#### 免费商用
go-platform 再次承诺，此框架将永久免费商用，纯爱发电～～
