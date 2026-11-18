import uniHelper from '@uni-helper/eslint-config'

export default uniHelper({}, {
  files: ['pnpm-workspace.yaml'],
  rules: {
    'pnpm/yaml-enforce-settings': 'off',
  },
})
