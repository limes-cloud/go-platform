import { defineUniPages } from '@uni-helper/vite-plugin-uni-pages'

export default defineUniPages({
  pages: [],
  globalStyle: {
    backgroundColor: '@bgColor',
    backgroundColorBottom: '@bgColorBottom',
    backgroundColorTop: '@bgColorTop',
    backgroundTextStyle: '@bgTxtStyle',
    navigationBarBackgroundColor: '@navBgColor',
    navigationBarTextStyle: '@navTxtStyle',
    navigationBarTitleText: 'PSou',
    navigationStyle: 'custom',
    rpxCalcMaxDeviceWidth: 750,
    rpxCalcBaseDeviceWidth: 750,
    rpxCalcIncludeWidth: 750,
  },
  easycom: {
    autoscan: true,
    custom: {
      '^u-(.*)': 'uview-pro/components/u-$1/u-$1.vue',
    },
  },
  subPackages: [],
})
