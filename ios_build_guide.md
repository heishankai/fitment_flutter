# iOS 打包指南

## 方法 1：使用 Flutter 命令行打包

### 1. 构建 iOS Release 版本
```bash
flutter build ios --release
```

### 2. 构建 IPA 文件（需要配置签名）
```bash
flutter build ipa
```

## 方法 2：使用 Xcode 打包

### 1. 打开 Xcode 项目
```bash
open ios/Runner.xcworkspace
```

### 2. 在 Xcode 中配置
- 选择 Product > Scheme > Runner
- 选择 Product > Destination > Any iOS Device
- 配置签名证书（Signing & Capabilities）
- 选择 Product > Archive

### 3. 导出 IPA
- 在 Organizer 中选择 Archive
- 点击 Distribute App
- 选择分发方式（App Store、Ad Hoc、Enterprise 等）

## 注意事项

1. **需要 Apple Developer 账号**（$99/年）
2. **配置 Bundle Identifier**：在 Xcode 中设置唯一的 Bundle ID
3. **配置签名证书**：在 Xcode 的 Signing & Capabilities 中配置
4. **网络权限**：如果使用 HTTP，需要在 Info.plist 中配置 ATS

