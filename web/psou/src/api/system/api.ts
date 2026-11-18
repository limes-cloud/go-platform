import type {
  App,
  BindReply,
  BindRequest,
  CreateFeedbackRequest,
  FillInfoItem,
  FillInfoRequest,
  GetImageCaptchaReply,
  GetImageCaptchaRquest,
  GetSampleAppRequest,
  InitAppRequest,
  ListAppTenantRequest,
  ListFeedbackClassifyReply,
  ListFeedbackClassifyRequest,
  ListFillInfoRequest,
  ListOAutherRequest,
  ListTenantReply,
  LoginReply,
  LoginRequest,
  OAuther,
  OAutherHandleReply,
  OAutherHandleRequest,
  OAutherLoginReply,
  OAutherLoginRequest,
  OAutherReportRequest,
  PrepareUploadFileReply,
  PrepareUploadFileRequest,
  RegisterReply,
  RegisterRequest,
  UpdateCurrentUserRequest,
  UploadFileReply,
  User,
} from './type'

import { request } from '@/library/request'

// GetApp 获取应用信息列表
export function GetSampleApp(params: GetSampleAppRequest) {
  return request.get<App>('/manager/api/sample/app', {
    params,
  })
}

// InitApp 根据页面访问域名初始化应用
export function InitApp(params: InitAppRequest) {
  const query: InitAppRequest = {}
  const domain = String(params.domain || '').trim()
  const appId = String(params.appId || '').trim()
  const platform = String(params.platform || '').trim()
  if (domain)
    query.domain = domain
  if (appId)
    query.appId = appId
  if (platform)
    query.platform = platform
  return request.get<App>('/manager/api/init', {
    params: query,
    custom: { hideError: true },
  })
}

// ListAppTenant 获取指定的应用租户信息列表
export function ListAppTenant(params: ListAppTenantRequest) {
  return request.get<ListTenantReply>('/manager/api/app/tenants', {
    params,
  })
}

// GetImageCaptcha 获取图像验证码
export function GetImageCaptcha(params: GetImageCaptchaRquest) {
  return request.get<GetImageCaptchaReply>('/manager/api/authorize/captcha/image', {
    params,
  })
}

export function OAutherLogin(data: OAutherLoginRequest, hideError = false) {
  return request.post<OAutherLoginReply>('/manager/api/authorize/oauther/login', data, {
    custom: { hideError },
  })
}

export function OAutherReport(data: OAutherReportRequest) {
  return request.post('/manager/api/authorize/oauther/report', data)
}

export function Login(data: LoginRequest) {
  return request.post<LoginReply>('/manager/api/authorize/login', data)
}

export function Logout() {
  return request.post('/manager/api/authorize/logout')
}

export function RefreshToken() {
  return request.post<LoginReply>('/manager/api/authorize/token/refresh')
}

export function Register(data: RegisterRequest) {
  return request.post<RegisterReply>('/manager/api/authorize/register', data)
}

export function Bind(data: BindRequest) {
  return request.post<BindReply>('/manager/api/authorize/oauther/bind', data)
}

// ListOAuther 获取租户应用授权信息列表
export function ListOAuther(params: ListOAutherRequest) {
  return request.get<{ list: OAuther[] }>('/manager/api/authorize/oauthers', {
    params,
  })
}

// ListOAuther 获取租户应用授权信息列表
export function OAutherHandle(data: OAutherHandleRequest) {
  return request.post<OAutherHandleReply>('/manager/api/authorize/oauther/handler', data)
}

// GetFileInfo 获取租户应用授权信息列表
export function ListFileInfo(params: ListFillInfoRequest) {
  return request.get<{ list: FillInfoItem[] }>('/manager/api/authorize/fill/infos', {
    params,
  })
}

// FillInfo 补充用户信息
export function FillInfo(data: FillInfoRequest) {
  return request.post<{ token: string }>('/manager/api/authorize/fill/infos', data)
}

// GetCurrentUser 获取当前用户信息
export function GetCurrentUser() {
  return request.get<User>('/manager/api/current/user')
}

// UpdateCurrentUser 更新当前用户信息
export function UpdateCurrentUser(data: UpdateCurrentUserRequest) {
  return request.put<User>('/manager/api/current/user', data)
}

export function PrepareUploadFile(data: PrepareUploadFileRequest) {
  return request.post<PrepareUploadFileReply>('/resource/api/file/prepare_upload', data)
}

export function UploadFile(file: any, params: Record<string, any>) {
  if (!params.store) {
    delete params.store
  }
  return request.upload<UploadFileReply>('/resource/api/upload', {
    filePath: file.url,
    name: 'data',
    formData: params,
    header: {
      'Content-Type': 'multipart/form-data',
    },
  })
}

export function UploadChunkFile(file: any, params: Record<string, any>) {
  params.data = file
  return request.upload('/resource/api/chunk_upload', {
    filePath: file.path,
    name: 'data',
    formData: params,
    header: {
      'Content-Type': 'multipart/form-data',
    },
  })
}

// CreateFeedback 创建反馈信息
export function CreateFeedback(data: CreateFeedbackRequest) {
  return request.post('/manager/api/feedback', data)
}

// ListFeedbackClassify 获取反馈分类列表
export function ListFeedbackClassify(params: ListFeedbackClassifyRequest) {
  return request.get<ListFeedbackClassifyReply>('/manager/api/feedback/classifies', { params })
}
