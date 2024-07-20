package conf

type Config struct {
	DefaultUserAvatar   string // 默认头像
	DefaultUserPassword string // 默认密码
	Setting             struct {
		Name      string
		Debug     bool
		Title     string
		Desc      string
		Copyright string
		Logo      string
		Watermark string
	}
	DictionaryKeywords []string
	ChangePasswordType string
}
