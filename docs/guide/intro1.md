
<div class="logo-container">
    <div class="particles" id="particles"></div>
    <div class="logo">
        <img src="/images/go.png" width="200" height="200"  alt=""/>
        <div class="highlight-text">Go-Platform 统一应用管理平台</div>
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

## 项目背景
在开始写GoPlatform之前，我也曾经尝试过很多开源的后台管理系统，目前市面上存在的开源系统都几乎存在以下几个问题：
#####  无法满足多端开发需求
目前几乎所有的开源系统都只能针对管理后台进行开发，实际上开发一个完整的系统，往往需要包含管理后台、移动端App、小程序等多个端口，而这些开源系统大多都无法满足这种需求，仅仅能满足管理后台的开发需求，对于用户端接入需要进行大量改造。

##### 无法进行细粒度鉴权
目前几乎所有的开源项目都是基于RBAC实现功能鉴权，系统鉴权能力、权限管理、菜单管理等功能几乎都比较薄弱，无法满足实际的业务需求，无法针对细粒度的权限进行控制，比如行级别、列级别、条件鉴权等，在很多场景下业务的数据存在安全隐患。

##### 必须侵入式开发
通常管理系统只是我们业务系统的基础能力，基于管理能力我们会去开发上层的业务功能，而目前市面上的开源系统大多都需要侵入式开发，必须基于系统的代码框架进行二次开发，无法做到解耦，导致我们无法将管理系统作为一个独立的服务进行部署和运维，对于大型的分布式系统来说，这种侵入式开发的方式是不可取的。

所以，我决定开发一个能够满足多端开发需求，能够进行细粒度鉴权，能够解耦的开源系统，能够让开发者只关注业务，Go-Platform应运而生。

## 系统演示

- 管理后台
  - 演示地址：[点击前往](https://demo.qlime.cn)  
  - 账号：admin  
  - 密码：12345678

- 移动H5端
  - 搭建中

### 版权说明
本人是一个技术宅，纯爱折腾，上班老老实实干活，下班写写开源项目，期望当前项目能给更多创业者，初学者带来一点价值，所以go-platform再次承诺，此框架将永久免费商用，纯爱发电～～。

同时也希望各位道友不吝啬手中的鼠标，就点个star吧，再次先感谢各位事业有成，蒸蒸日上，天天开心。

### 技术交流

<div class="logo-container">
    <div class="logo jl">
        <img src="/images/qq.png" width="180" height="180"  alt=""/>
        <div class="desc-text">QQ交流群</div>
    </div>
    <div class="logo jl">
        <img src="/images/wx.png" width="180" height="180"  alt=""/>
        <div class="desc-text">开发者微信</div>
    </div>
</div>


### 功能介绍

### 计划任务

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

.logo div {
    margin-top: 20px;
    font-size: 1.4rem;
    font-weight: bold;
    position: relative;
    padding: 10px;
    overflow: hidden;
    text-align: center;
}

.desc-text{
     margin-top: 0px !important;
    font-size: 12px !important;
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
