export interface Tenant {
  id: number
  logo: string
  keyword: string
  name: string
  status?: boolean
  description?: string
  weight: number
  createdAt: number
  updatedAt: number
}

export interface GetSampleAppRequest {
  keyword: string
}

export interface InitAppRequest {
  domain?: string
  appId?: string
  platform?: string
}

export interface AppSetting {
  tenant: {
    mode: string
  }
  web: {
    watermark?: string
    copyright?: string
  }
  tracker?: {
    enable?: boolean
    origins?: string[]
    maxPoints?: number
    conversionPoint?: string
  }
}

export interface App {
  id: number
  type: string
  logo: string
  favicon: string
  keyword: string
  name: string
  showName: string
  secret?: string
  comment?: string
  status?: boolean
  reason?: string
  private?: boolean
  setting?: AppSetting
  description?: string
  copyright?: string
  watermark?: string
  selectTenant?: boolean
  createdAt: number
  updatedAt: number
}

export interface LoginRequest {
  tenant: string
  app: string
  username: string
  password: string
  captchaId: string
  captcha: string
}

export interface LoginReply {
  needInfo: boolean
  token: string
}

export interface RegisterRequest {
  tenant: string
  app: string
  username: string
  password: string
  rePassword: string
  captchaId: string
  captcha: string
}

export interface RegisterReply {
  token: string
  needInfo: boolean
}

export interface BindRequest {
  username: string
  password: string
  captchaId: string
  captcha: string
  uuid: string
  register: boolean
}

export interface BindReply {
  needInfo: boolean
  token: string
}

export interface GetImageCaptchaRquest {
  scene: string
}

export interface GetImageCaptchaReply {
  uuid: string
  captcha: string
  expire: number
}

export interface OAuther {
  id: number
  logo: string
  keyword: string
  name: string
  type: string
  recommend: boolean
  recommendText: string
}

export interface ListOAutherRequest {
  app: string
  tenant: string
  platform: string
}

export interface OAutherHandleRequest {
  tenant: string
  app: string
  account?: string
  keyword: string
  platform: string
}

export interface OAutherHandleReply {
  uuid: string
  action: string
  value: string
  tip: string
  keyword: string
  codeField: string
}

export interface OAutherReportRequest {
  uuid: string
  code?: string
}

export interface OAutherLoginRequest {
  uuid: string
  keyword?: string
  account?: string
  code?: string
}

export interface OAutherLoginReply {
  needBind: boolean
  needInfo: boolean
  token: string
}

export interface ListFillInfoRequest {
  uuid: string
}

export interface FillInfoItem {
  type: string
  keyword: string
  name: string
  value: any
}

export interface FillInfoRequest {
  uuid: string
  infos: Record<string, any>
}

export interface ListAppTenantRequest {
  app: string
}

export interface Tenant {
  id: number
  logo: string
  keyword: string
  name: string
  status?: boolean
  description?: string
  weight: number
  createdAt: number
  updatedAt: number
}

export interface ListTenantReply {
  total: number
  list: Tenant[]
}

export interface UserDept {
  dept: {
    id: number
    name: string
    main: boolean
  }
  job: {
    id: number
    name: string
  }
}

export interface User {
  id: number
  avatar: string
  username: string
  nickname: string
  signature: string
  status?: boolean
  userDepts: UserDept[]
  loggedAt: number
  createdAt: number
  updatedAt: number
}

export interface Field {
  id: number
  keyword: string
  name: string
  type: string
}

export interface PrepareUploadFileRequest {
  directoryId?: number
  directoryPath?: string
  store?: string
  name: string
  size: number
  sha: string
}

export interface PrepareUploadFileReply {
  uploaded: boolean
  chunkSize?: number
  chunkCount?: number
  uploadId?: string
  uploadChunks?: number[]
  sha?: string
  key?: string
}

export interface UploadFileReply {
  sha: string
  key: string
}

export interface UpdateFileRequest {
  id: number
  directoryId: number
  name: string
  store?: string
}

export interface UpdateCurrentUserRequest {
  nickname: string
  avatar: string
  signature: string
}

// 反馈相关
export interface ListFeedbackClassifyRequest {
  page: number
  pageSize: number
  order?: string
  orderBy?: string
  name?: string
}

export interface FeedbackClassify {
  id: number
  name: string
  createdAt: number
  updatedAt: number
}

export interface ListFeedbackClassifyReply {
  total: number
  list: FeedbackClassify[]
}

export interface CreateFeedbackRequest {
  appId: number
  classifyId: number
  title: string
  content: string
  images?: string
  imageUrls?: string[]
  contact?: string
  device: string
  platform: string
  version: string
}
