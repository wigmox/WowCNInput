# 更新日志

## [0.2.0](https://github.com/wigmox/WowCNInput/compare/v0.1.0...v0.2.0) (2026-04-09)


### Features

* 修改文件加载流程 ([d8b50a0](https://github.com/wigmox/WowCNInput/commit/d8b50a085caeeac170c22b70c2e9213ca5461269))
* 增加全词动态调频。 ([f3c27f2](https://github.com/wigmox/WowCNInput/commit/f3c27f24b9921aacf44759a4e9c5b654dfd6c7ed))
* 添加 -Dragonflight3 输入框支持。 ([e6b35ee](https://github.com/wigmox/WowCNInput/commit/e6b35ee26464ca0260a913c2dd16b55be8ba79e1))
* 添加小地图图标 ([9b30a55](https://github.com/wigmox/WowCNInput/commit/9b30a55ceb476298bbad9cdb76bccf5635801a48))
* 添加自定义词库优先功能，本地自定义词库优先到首位 ([c09e65f](https://github.com/wigmox/WowCNInput/commit/c09e65f2e3d6a1a5f21bc962e7d91c64e423d2a4))
* 添加设置界面小地图图标开关功能。 ([0d89b30](https://github.com/wigmox/WowCNInput/commit/0d89b30fe4e1d6299c62cb4da6530d575dec934f))
* 添加输入候选框长度、缩放，以及输入字母/候选字大小调整功能 ([67df087](https://github.com/wigmox/WowCNInput/commit/67df08745acb06f8870d7197a70c1d3d7636c3f2))


### Bug Fixes

* 修复小地图图标按下错误的问题。 ([0d89b30](https://github.com/wigmox/WowCNInput/commit/0d89b30fe4e1d6299c62cb4da6530d575dec934f))
* 修复开启全词调频后时间戳没有清缓存，更新不及时的问题。 ([f3c27f2](https://github.com/wigmox/WowCNInput/commit/f3c27f24b9921aacf44759a4e9c5b654dfd6c7ed))
* 修复编辑框判断，预防报错。 ([e6b35ee](https://github.com/wigmox/WowCNInput/commit/e6b35ee26464ca0260a913c2dd16b55be8ba79e1))
* 修复设置界面用户词库不显示的问题 ([a6392b5](https://github.com/wigmox/WowCNInput/commit/a6392b52eda4c2e23a7c5fd48906e1038d040def))

## [0.1.0](https://github.com/wigmox/WowCNInput/compare/v0.0.8...v0.1.0) (2026-03-25)


### Features

* 优化分词逻辑，现在可以设置2中分词逻辑，在设置界面可以手动调整。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 候选添加缓存功能，默认300条，设置界面可以调整。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 对调整输入框到顶部添加了开关选项，默认启用。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 添加了常用的声母字库，输入单个声母也会适配常用字 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 添加用户自定义词库，通过学习输入词库保存到自定义词库内，下次直接调用。默认保存 1000条，设置界面可以调整。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 添加设置界面，可以通过设置界面调整设置开关，词库等信息。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 添加词库，包括日常词库，魔兽专用词库等。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 设置界面添加了 Debug 开关，方便调试。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 重构 lua 文件，按功能分文件保存执行。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))


### Bug Fixes

* 修复了 宏界面、邮件正文等多行输入栏 输入英文自动回车的问题。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 修复了插件打包命令。 ([6ac2b1d](https://github.com/wigmox/WowCNInput/commit/6ac2b1d2b40388b71859276eb8b2c076e937171d))
* 修改了自定义保存数据名 ([eb16e7b](https://github.com/wigmox/WowCNInput/commit/eb16e7b4fe2a3884740d1654651534461ccabaa7))
* 统一化了保存函数命名格式 ([eb16e7b](https://github.com/wigmox/WowCNInput/commit/eb16e7b4fe2a3884740d1654651534461ccabaa7))

## [0.0.8](https://github.com/wigmox/WowCNInput/compare/v0.0.7...v0.0.8) (2026-03-02)


### Bug Fixes

* Bump version from 0.0.6 to 0.0.7 ([6436ac7](https://github.com/wigmox/WowCNInput/commit/6436ac74abdfd55c2284c243c696c39696630390))
* 测试版本更新 ([b073232](https://github.com/wigmox/WowCNInput/commit/b0732324ea83a076e44b4756ebe3881cdacf6a1e))

## [0.0.7](https://github.com/wigmox/WowCNInput/compare/v0.0.6...v0.0.7) (2026-03-02)


### Bug Fixes

* 修复打包失败问题 ([6d91844](https://github.com/wigmox/WowCNInput/commit/6d91844a469b048f870c3bd5cdd38c137f2c44f4))

## [0.0.6](https://github.com/wigmox/WowCNInput/compare/v0.0.5...v0.0.6) (2026-03-02)


### Bug Fixes

* Change upload action to softprops/action-gh-release@v2 ([3803353](https://github.com/wigmox/WowCNInput/commit/38033537aa6f99da0a914febcad4e60bb3a1cdf4))
* 修复版本号无法正确修改的问题 ([92df0e5](https://github.com/wigmox/WowCNInput/commit/92df0e5dd98eeb5f5f5b1bfd9e1c4b6d365dfab3))
* 修复版本号错误 ([3e1baf2](https://github.com/wigmox/WowCNInput/commit/3e1baf255211dbbe6026c3a267040524629a9d02))

## [0.0.5](https://github.com/wigmox/WowCNInput/compare/v0.0.4...v0.0.5) (2026-03-01)


### Bug Fixes

* 修复按键绑定不显示中文问题。修复登录后聊天界面不显示中文输入说明信息的问题。 ([cf1c3df](https://github.com/wigmox/WowCNInput/commit/cf1c3dfeb95501bec72b70771e379f1553e6f2be))
* 修复按键绑定不显示中文问题。修复登录后聊天界面不显示中文输入说明信息的问题。 ([d8df538](https://github.com/wigmox/WowCNInput/commit/d8df538aecccc834a5f7941d5fbcabe96e57b00f))

## [0.0.4](https://github.com/wigmox/WowCNInput/compare/v0.0.3...v0.0.4) (2026-02-28)


### Bug Fixes

* Enhance release workflow with asset packaging and upload ([467f44c](https://github.com/wigmox/WowCNInput/commit/467f44c5483933b999de2e8c83600f03fb6bf5e9))

## [0.0.3](https://github.com/wigmox/WowCNInput/compare/v0.0.2...v0.0.3) (2026-02-28)


### Bug Fixes

* 修复按键绑定，可以通过绑定按键切换中文输入。 ([913156d](https://github.com/wigmox/WowCNInput/commit/913156d3847eedc9325572c89abd86de013b6925))

## [0.0.2] - 2026-02-28
### 候选双行显示
拼音候选单独显示一行

### 屏幕防遮挡
聊天输入框移动到顶部居中位置

### 新增输入模式
可以分段候选
比如输入：woainizhongguo（我爱你中国）
可以最大化适配，通过空格可以连续候选

### 新增支持中文输入区域
增加输入范围现在支持
-- 聊天框架编辑框
-- 宏命令输入框
-- 宏新建起名框
-- 公会信息框（未测试）
-- 公会公告框（未测试）
-- 好友面板：添加好友
-- 好友面板：屏蔽玩家
-- 邮件：收件人
-- 邮件：主题
-- 邮件：正文
-- 拍卖行搜索（仅系统默认模式，拍卖行插件不支持）
-- 各种系统弹窗输入框（如公会邀请、改名等）（未测试）

### ⚡ 性能优化

#### GetDynamicCandidates 函数优化
优化候选逻辑，减少负载压力。减少输入时的卡顿

### 📝 代码质量提升

- 添加完整的函数级注释，说明函数用途、参数和返回值
- 统一代码风格，使用4空格缩进
- 遵循 Lua 5.0 语法限制（WoW 1.12 环境）
- 所有变量命名遵循统一的命名规范

### 🔧 兼容性

- 保持与原插件功能完全一致
- 支持拼音
- 支持所有原有输入场景
- 保持向后兼容

---

## [0.0.1] - 初始版本 - 2026-02-26

### 初始功能
- 拼音输入法支持
- 候选词翻页功能
