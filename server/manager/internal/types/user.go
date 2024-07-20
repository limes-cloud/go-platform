package types

type GetUserRequest struct {
	Id    *uint32 `json:"id"`
	Phone *string `json:"phone"`
	Email *string `json:"email"`
}

type ListUserRequest struct {
	Page          uint32   `json:"page"`
	PageSize      uint32   `json:"pageSize"`
	Order         *string  `json:"order"`
	OrderBy       *string  `json:"orderBy"`
	DepartmentId  *uint32  `json:"departmentId"`
	RoleId        *uint32  `json:"roleId"`
	Name          *string  `json:"name"`
	Phone         *string  `json:"phone"`
	Email         *string  `json:"email"`
	Status        *bool    `json:"status"`
	LoggedAts     []int64  `json:"loggedAts"`
	CreatedAts    []int64  `json:"createdAts"`
	DepartmentIds []uint32 `json:"departmentIds"`
}

type UpdateCurrentUserRequest struct {
	Avatar   *string `json:"avatar"`
	Nickname string  `json:"nickname"`
	Gender   string  `json:"gender"`
}

type UpdateCurrentUserPasswordRequest struct {
	Password    string  `json:"password"`
	OldPassword *string `json:"oldPassword"`
	CaptchaId   *string `json:"captchaId"`
	Captcha     *string `json:"captcha"`
}

type SendCurrentUserCaptchaReply struct {
	Uuid    string `json:"uuid"`
	Captcha string `json:"captcha"`
	Expire  uint32 `json:"expire"`
}

type GetUserLoginCaptchaReply struct {
	Uuid    string `json:"uuid"`
	Captcha string `json:"captcha"`
	Expire  uint32 `json:"expire"`
}

type UserLoginRequest struct {
	Username  string `json:"username"`
	Password  string `json:"password"`
	CaptchaId string `json:"captchaId"`
	Captcha   string `json:"captcha"`
}
