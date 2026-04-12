# Fitment Flutter - 装修 APP

## 启动模拟器

1. 创建工程： flutter create domo

2. 启动 ios 模拟器：
   - iOS 17.0: `xcrun simctl boot 0237DD1A-46FD-4BB7-B09E-D4518A8C1779 && open -a Simulator`
   - iOS 17.5: `xcrun simctl boot C90659F2-8600-4C5E-AA3A-038DF92EA13B && open -a Simulator`
   - 或者使用设备名称（如果唯一）: `xcrun simctl boot "iPhone 15 Pro" && open -a Simulator`

3. 启动 android 模拟器 :

- 后台运行：$ANDROID_HOME/emulator/emulator -avd Pixel_9_Pro &
- 前台运行：$ANDROID_HOME/emulator/emulator -avd Pixel_9_Pro

4. 启动项目：
   - 自动选择设备：`flutter run`
   - 指定设备：`flutter run -d "iPhone 15 Pro"`
   - 查看可用设备：`flutter devices`

5. 只创建 ios 和 安卓项目：`flutter create --platforms android,ios fitment_flutter`

## 后台订单通知说明

**现象**：App 切到后台后，新订单来了没有通知、没有震动，Socket 也不生效。

**原因**：iOS/Android 为省电，应用进入后台后会**暂停网络连接**（Socket 被系统挂起），应用代码几乎不执行，因此：
- Socket 收不到 `new-order` 事件
- `NewOrderNotification` 不会被调用
- 震动和本地通知都不会触发

**当前实现**：
- 前台：Socket 正常，新订单会触发震动 + 本地通知
- 从后台切回前台：会自动重连 Socket，并刷新订单列表

**如需后台也能收到新订单通知**，需要接入 **服务端推送（FCM/APNs）**：
1. 集成 `firebase_messaging`，获取设备 FCM Token 并上报给后端
2. 后端在有新订单时，通过 FCM/APNs 发送推送
3. 系统会在后台/应用未运行时也能把通知推给用户

## 故障排除

### iOS 模拟器问题

如果遇到 "Unable to find a destination matching the provided destination specifier" 错误：

1. 清理 Flutter 构建缓存：

   ```bash
   flutter clean
   ```

2. 清理 Xcode 派生数据：

   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

3. 重启模拟器：

   ```bash
   xcrun simctl shutdown all
   xcrun simctl boot C90659F2-8600-4C5E-AA3A-038DF92EA13B
   open -a Simulator
   ```

4. 使用指定设备 ID 运行：

   ```bash
   flutter run -d C90659F2-8600-4C5E-AA3A-038DF92EA13B
   ```

5. 查看所有可用模拟器：
   ```bash
   xcrun simctl list devices available
   ```

## Android 打包和运行

### 使用 Flutter 命令行打包

1. **构建 Android Release APK**：

   ```bash
   flutter build apk --release
   ```

   构建完成后，APK 文件会生成在 `build/app/outputs/flutter-apk/app-release.apk`

2. **构建分架构的 APK（减小文件大小）**：

   ```bash
   # 构建 ARM64 版本（推荐，兼容大部分设备）
   flutter build apk --release --target-platform android-arm64

   # 构建所有架构版本
   flutter build apk --release --split-per-abi
   ```

   分架构版本会生成在 `build/app/outputs/flutter-apk/` 目录下：
   - `app-armeabi-v7a-release.apk` (32位 ARM)
   - `app-arm64-v8a-release.apk` (64位 ARM，推荐)
   - `app-x86_64-release.apk` (64位 x86)

### 安装 APK 到设备

1. **通过 USB 连接安装**：

   ```bash
   # 连接 Android 设备后
   flutter install
   ```

2. **手动安装**：
   - 将 `app-release.apk` 文件传输到 Android 设备
   - 在设备上打开文件管理器，找到 APK 文件
   - 点击安装（需要允许"未知来源"安装权限）

3. **通过 ADB 安装**：
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### Android 打包配置

- **应用 ID**：`com.example.fitment_flutter`（可在 `android/app/build.gradle` 中修改）
- **版本号**：`1.0.0+1`（在 `pubspec.yaml` 中配置）
- **应用名称**：`叮当优+`（在 `android/app/src/main/AndroidManifest.xml` 中配置）
- **签名配置**：当前使用 debug 签名（发布前需要配置 release 签名）

### 常见问题

1. **构建失败 - NDK 问题**：
   - 确保已安装 Android NDK
   - 在 Android Studio 中：**Tools > SDK Manager > SDK Tools**，勾选 **NDK**

2. **构建失败 - 许可证未接受**：

   ```bash
   flutter doctor --android-licenses
   ```

   按提示接受所有许可证

3. **APK 文件过大**：
   - 使用 `--split-per-abi` 构建分架构版本
   - 使用 `flutter build appbundle` 构建 AAB（Google Play 会自动优化）

4. **安装失败 - 签名冲突**：
   - 卸载旧版本应用
   - 或使用不同的签名密钥重新构建

## iOS 打包和运行

### 使用 Flutter 命令行打包

1. **构建 iOS Release 版本**：

   ```bash
   flutter build ios --release
   ```

   构建完成后，应用会生成在 `build/ios/iphoneos/Runner.app`

2. **构建 IPA 文件**：

   **开发版本（推荐，用于真机测试）**：

   ```bash
   flutter build ipa --export-method development
   ```

   构建完成后，IPA 文件会生成在 `build/ios/ipa/`，可以直接安装到已注册的设备上

   **App Store 版本（需要 Distribution 证书）**：

   ```bash
   flutter build ipa
   ```

   注意：需要有效的 Apple Developer 账号和 Distribution 证书

   **Ad-Hoc 版本（用于内测分发）**：

   ```bash
   flutter build ipa --export-method ad-hoc
   ```

### 使用已打包的文件安装到设备

如果你已经打包好了 IPA 或 Archive 文件，可以直接安装到设备，无需重新编译：

#### 方法 1：通过 Xcode 安装 IPA（推荐）

1. **连接 iPhone 到 Mac**：
   - 使用 USB 数据线连接
   - 在 iPhone 上点击"信任此电脑"（首次连接）

2. **打开 Xcode Devices 窗口**：
   - 在 Xcode 菜单选择：**Window > Devices and Simulators**
   - 或按快捷键：`Shift + Cmd + 2`

3. **选择你的 iPhone**：
   - 在左侧设备列表中选择你的 iPhone
   - 确保设备状态显示为"已连接"

4. **安装 IPA**：
   - 在右侧窗口，找到 **Installed Apps** 区域
   - 点击下方的 **+** 按钮
   - 浏览并选择 `build/ios/ipa/fitment_flutter.ipa` 文件
   - 点击 **Open**
   - Xcode 会自动安装应用到你的 iPhone

5. **信任开发者证书**（首次安装）：
   - 在 iPhone 上：**设置 > 通用 > VPN与设备管理**（或设备管理）
   - 找到你的开发者证书，点击并选择"信任"
   - 返回桌面，打开应用

#### 方法 2：通过 Finder 安装 IPA（macOS Catalina 及以后）

1. **连接 iPhone 到 Mac**

2. **打开 Finder**：
   - 在 Finder 左侧边栏，点击你的 iPhone 设备名称

3. **拖拽安装**：
   - 将 `build/ios/ipa/fitment_flutter.ipa` 文件直接拖拽到 Finder 窗口
   - 应用会自动安装

4. **信任开发者证书**（同上）

#### 方法 3：使用 Archive 文件安装

如果你有 `.xcarchive` 文件（位于 `build/ios/archive/Runner.xcarchive`）：

1. **打开 Archive**：

   ```bash
   open build/ios/archive/Runner.xcarchive
   ```

   这会打开 Xcode Organizer 窗口

2. **导出并安装**：
   - 在 Organizer 中选择你的 Archive
   - 点击 **Distribute App**
   - 选择 **Development**（用于开发测试）
   - 选择 **Automatically manage signing**
   - 点击 **Next**，选择导出位置
   - 导出完成后，使用上面的方法 1 安装 IPA

#### 方法 4：使用第三方工具安装

- **3uTools**、**爱思助手** 等工具也可以安装 IPA 文件
- 连接设备后，选择"安装应用"，选择 IPA 文件即可

### 在 Xcode 中连接手机运行（重新编译）

#### 步骤 1：打开 Xcode 项目

```bash
open ios/Runner.xcworkspace
```

**注意**：必须打开 `.xcworkspace` 文件，而不是 `.xcodeproj` 文件

#### 步骤 2：连接 iPhone 设备

1. 使用 USB 数据线将 iPhone 连接到 Mac
2. 在 iPhone 上点击"信任此电脑"（如果首次连接）
3. 在 Xcode 顶部工具栏的设备选择器中，应该能看到你的 iPhone

#### 步骤 3：配置签名（如果需要）

1. 在 Xcode 左侧项目导航器中，点击 **Runner** 项目（最顶部的蓝色图标）
2. 选择 **Runner** target
3. 点击 **Signing & Capabilities** 标签
4. 确保 **Automatically manage signing** 已勾选
5. 在 **Team** 下拉菜单中选择你的开发团队（当前已配置：3R26C4PZT2）
6. 如果出现错误，Xcode 会自动创建或更新 Provisioning Profile

#### 步骤 4：选择设备和运行

1. 在 Xcode 顶部工具栏，点击设备选择器（显示 "Any iOS Device" 或模拟器名称的地方）
2. 选择你连接的 iPhone 设备
3. 点击左侧的 **运行按钮**（▶️）或按快捷键 `Cmd + R`
4. 首次运行时，可能需要在 iPhone 上：
   - 进入 **设置 > 通用 > VPN与设备管理**
   - 信任你的开发者证书
   - 返回应用，重新打开

#### 步骤 5：查看构建日志

- 如果构建失败，查看 Xcode 底部的 **Issue Navigator**（⚠️ 图标）查看错误信息
- 查看 **Report Navigator**（📊 图标）查看详细的构建日志

### 在 Xcode 中打包 IPA（推荐方法）

如果命令行打包遇到签名问题，可以在 Xcode 中直接打包：

#### 方法 1：使用已生成的 Archive

1. Archive 已经生成在：`build/ios/archive/Runner.xcarchive`
2. 在终端运行：
   ```bash
   open build/ios/archive/Runner.xcarchive
   ```
3. 或者手动打开 Xcode Organizer：
   - 在 Xcode 菜单选择 **Window > Organizer** (Shift + Cmd + O)
   - 点击 **Archives** 标签
   - 找到你的 Archive（如果没有显示，点击 **Import** 导入 `build/ios/archive/Runner.xcarchive`）

4. 导出 IPA：
   - 选择你的 Archive
   - 点击 **Distribute App** 按钮
   - 选择分发方式：
     - **Development**：用于开发测试（推荐）
     - **Ad Hoc**：用于内测分发
     - **App Store Connect**：用于 App Store 发布
     - **Enterprise**：企业内部分发（需要企业账号）
   - 选择签名方式：**Automatically manage signing**（推荐）
   - 点击 **Next**，Xcode 会自动处理签名和导出
   - 选择保存位置，IPA 文件会导出到指定位置

#### 方法 2：在 Xcode 中重新 Archive

1. 打开项目：`open ios/Runner.xcworkspace`
2. 在 Xcode 顶部选择 **Any iOS Device** 或你的真机设备（不能选择模拟器）
3. 在菜单选择 **Product > Archive**
4. 等待 Archive 完成（可能需要几分钟）
5. Archive 完成后，会自动打开 Organizer 窗口
6. 按照上面的步骤 4 导出 IPA

### 常见问题

1. **签名错误**：
   - 确保在 Xcode 中选择了正确的 Team
   - 确保 Bundle Identifier 是唯一的（当前：`com.example.fitmentFlutter`）
   - 如果 Bundle ID 冲突，可以在 Xcode 中修改为你的唯一标识符

2. **设备未显示**：
   - 检查 USB 连接
   - 确保 iPhone 已解锁并信任此电脑
   - 在 Xcode 菜单：**Window > Devices and Simulators** 中检查设备状态

3. **构建失败**：
   - 清理项目：`flutter clean` 然后 `flutter pub get`
   - 在 Xcode 中：**Product > Clean Build Folder** (Shift + Cmd + K)
   - 重新打开 Xcode 项目

4. **应用无法安装到设备**：
   - 检查 iPhone 的 iOS 版本是否支持（需要 iOS 12.0 或更高）
   - 确保开发者账号有足够的设备注册数量

5. **IPA 打包失败（No signing certificate "iOS Distribution" found）**：
   - 如果使用免费 Apple ID，只能使用 `development` 方法：
     ```bash
     flutter build ipa --export-method development
     ```
   - 如果使用付费 Apple Developer 账号，确保：
     - 在 Apple Developer 网站创建了 App ID
     - 下载并安装了 Distribution 证书
     - 创建了相应的 Provisioning Profile
   - 或者直接在 Xcode 中导出 IPA：
     - 打开 `build/ios/archive/Runner.xcarchive`
     - 在 Xcode 中选择 **Window > Organizer**
     - 选择你的 Archive，点击 **Distribute App**
     - 选择分发方式（Development/Ad-Hoc/App Store）

# 项目处理

- 清空缓存：flutter clean
- 重新下载依赖：flutter pub get
- stful : 快捷创建有状态的 widget
- stless : 快捷创建无状态的 widget
