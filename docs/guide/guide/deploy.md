<div class="logo-container">
    <div class="particles" id="particles"></div>
    <div class="logo">
        <img src="/images/go.png" width="200" height="200"  alt=""/>
        <div class="highlight-text">Go-Platform 统一应用管理平台</div>
        <div class="highlight-text-desc">Go-Kratos+Vue3+UniApp 多应用多租户快速开发框架，助力个人/中小企业应用快速落地</div>
    </div>
</div>

<div class="tag">
    <div class="tag-item">
        <img src="https://img.shields.io/badge/golang-1.24-blue" alt=""/>
    </div>
    <div class="tag-item">
        <img src="https://img.shields.io/badge/kratos-2.7.2-red" alt=""/>
    </div>
    <div class="tag-item">
        <img src="https://img.shields.io/badge/vue-3.3.4-bright" alt=""/>
    </div>
    <div class="tag-item">
        <img src="https://img.shields.io/badge/art.design-2.52-orange" alt=""/>
    </div>
    <div class="tag-item">
        <img src="https://img.shields.io/badge/uni.app-1.25.2-cyan" alt=""/>
    </div>
    <div class="tag-item">
        <img src="https://img.shields.io/badge/uv.ui-1.19.1-bright" alt=""/>
    </div>
</div> 

## 系统演示

| 平台     | 演示地址     | 登陆账号    | 登陆密码     | 备注     |
|--------------|--------------|--------------|--------------|--------------|
| 管理端 | [点击前往](https://demo.qlime.cn)  | username | 12345678 | 统一管理端 |
| 应用端 | 搭建中  | username | 12345678 | 统一管理端 |



## 项目由来
在开始写GoPlatform之前，我也曾经尝试过很多开源的后台管理系统，目前市面上存在的开源系统都几乎存在以下几个问题：
#####  无法满足多端开发需求
目前几乎所有的开源系统都只能针对管理后台进行开发，实际上开发一个完整的系统，往往需要包含管理后台、移动端App、小程序等多个端口，而这些开源系统大多都无法满足这种需求，仅仅能满足管理后台的开发需求，对于用户端接入需要进行大量改造。

##### 无法进行细粒度鉴权
目前几乎所有的开源项目都是基于RBAC实现功能鉴权，系统鉴权能力、权限管理、菜单管理等功能几乎都比较薄弱，无法满足实际的业务需求，无法针对细粒度的权限进行控制，比如行级别、列级别、条件鉴权等，在很多场景下业务的数据存在安全隐患。

##### 必须侵入式开发
通常管理系统只是我们业务系统的基础能力，基于管理能力我们会去开发上层的业务功能，而目前市面上的开源系统大多都需要侵入式开发，必须基于系统的代码框架进行二次开发，无法做到解耦，导致我们无法将管理系统作为一个独立的服务进行部署和运维，对于大型的分布式系统来说，这种侵入式开发的方式是不可取的。

所以，我决定开发一个能够满足多端开发需求，能够进行细粒度鉴权，能够解耦的开源系统，能够让开发者只关注业务，Go-Platform应运而生。

## 框架优势

- 🚀 分布式：项目基于Go-Kratos，开发层面上充分考虑了单机、分布式场景，能够单机部署，也可以多节点（k8s）部署。
- ⚡ 高性能：项目中充分使用缓存等机制，对API鉴权、数据鉴权非常快速。
- 🪝 数据安全：项目在RBAC的基础上优化，支持行、列级别的细粒度控制。
- ✨ 易用性强：API 设计现代，文档详尽，开发体验优于传统兼容方案。
- 🌐 生态完善： 项目包含管理中心、资源中心、配置中心等多个基础中台，为项目开发提速。
- 🌙 无侵入性：第三方业务平台直接接入，无需关注平台鉴权逻辑.


## 版权说明

GoPlatform 遵循 [MIT](https://baike.baidu.com/item/MIT%E8%AE%B8%E5%8F%AF%E8%AF%81/6671281?fromtitle=MIT&fromid=10772952) 开源协议，无论您是个人、企业都可以免费使用。

注意：禁止用于非法领域（如赌博、暴力等），如因此产生纠纷，GoPlatform 不承担任何责任。

本人是一个技术宅，纯爱折腾，上班老老实实干活，下班写写开源项目，期望当前项目能给更多创业者，初学者带来一点价值，所以go-platform再次承诺，此框架将永久免费商用，纯爱发电～～。
同时也希望各位道友不吝啬手中的鼠标，就点个star吧，再次先感谢各位事业有成，蒸蒸日上，天天开心。



### 技术交流

<div class="logo-container">
    <div class="logo jl">
        <img src="/images/qq.png" width="220" height="220"  alt=""/>
        <div class="desc-text">QQ交流群</div>
    </div>
    <div class="logo jl">
        <img src="/images/wx.png" width="220" height="220"  alt=""/>
        <div class="desc-text">开发者微信</div>
    </div>
</div>

## 项目鸣谢

[Go-Kratos](https://github.com/go-kratos/kratos)：Kratos 一套轻量级 Go 微服务框架，包含大量微服务相关功能及工具。

[Uni-App](https://uniapp.dcloud.net.cn)：是一个使用 Vue.js 开发所有前端应用的框架，开发者编写一套代码，多端部署

[Element-Plus](https://uniapp.dcloud.net.cn)：是一个使用 Vue.js 开发所有前端应用的框架，开发者编写一套代码，多端部署

[Art Design Pro](https://www.artd.pro/docs/zh/)：一款兼具设计美学与高效开发的后台系统模版

## 项目捐赠


GoPlatform文档和源码全部开源免费。如果 GoPlatform 对您的开发工作有所帮助，欢迎捐赠支持项目持续维护与更新。捐赠金额不限，哪怕是一杯可乐，也能带来莫大的鼓励！

<div class="logo-container">
    <div class="logo jl">
        <img src="/images/wx-zs.png" width="220" height="220"  alt=""/>
        <div class="desc-text">微信赞赏码</div>
    </div>
    <div class="logo jl">
        <img src="/images/zfb-zs.png" width="220" height="220"  alt=""/>
        <div class="desc-text">支付宝收款码</div>
    </div>
</div>
下方为历史捐赠者名单，无论金额多少，我们都心怀感激，感谢您的支持！
如有遗漏，请及时联系我们，我们会尽快补充。

| 昵称     | 金额(元)     | 日期    | 平台     | 留言     |
|--------------|--------------|--------------|--------------|--------------|
| 自己 | 79元 | 12-01 | 微信 | 买服务器 |


<style scoped>

.logo-container {
    position: relative;
    z-index: 2;
    padding: 10px;
    border-radius: 15px;
    backdrop-filter: blur(10px);
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
}

.logo {
    width: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    display: flex;
    align-items: center;
    border-radius: 10px;
}

.logo img {
    filter: drop-shadow(0 0 10px rgba(0, 255, 255, 0.5));
}

.logo .highlight-text {
    margin-top: 20px;
    font-size: 1.4rem;
    font-weight: bold;
    position: relative;
    padding: 10px;
    overflow: hidden;
    text-align: center;
}

.desc-text{
    margin-top: 5px !important;
    font-size: 16px !important;
}

.jl{
    padding: 15px;
}

.jl img {
    filter: drop-shadow(0 0 10px rgba(0, 0, 0, 0.1));
    border-radius: 8px;
}


.highlight-text {
    background: linear-gradient(
        90deg,
        #ff3366, #ff9933, #ffcc00, 
        #66cc33, #33ccff, #9966ff, 
        #ff3366
    );
    background-size: 400% 100%;
    -webkit-background-clip: text;
    background-clip: text;
    -webkit-text-fill-color: transparent;
    animation: colorful-highlight 6s linear infinite;
}

.highlight-text-desc{
    font-size: 14px !important;
    color: #999;
}

@keyframes colorful-highlight {
    0% {
        background-position: -100% 0;
    }
    100% {
        background-position: 200% 0;
    }
}
        
.tag{
    display: flex;
    justify-content: center;
}
.tag-item{
    padding: 10px 2px;
}
</style>
