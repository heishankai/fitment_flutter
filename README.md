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
