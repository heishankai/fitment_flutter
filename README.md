# Fitment Flutter

## 启动模拟器

### iOS 模拟器

1. **列出可用的iOS模拟器：**
   ```bash
   flutter emulators
   ```

2. **启动指定的iOS模拟器：**
   ```bash
   flutter emulators --launch <emulator_id>
   ```
   例如：
   ```bash
   flutter emulators --launch apple_ios_simulator
   ```

3. **或者直接打开iOS模拟器：**
   ```bash
   open -a Simulator
   ```

4. **在已启动的模拟器上运行应用：**
   ```bash
   flutter run
   ```

### Android 模拟器

1. **列出可用的Android模拟器：**
   ```bash
   flutter emulators
   ```
   或查看所有AVD：
   ```bash
   emulator -list-avds
   ```

2. **启动指定的Android模拟器：**
   ```bash
   flutter emulators --launch <emulator_id>
   ```
   例如：
   ```bash
   flutter emulators --launch Pixel_3a_API_30_x86
   ```

3. **或者直接使用emulator命令：**
   ```bash
   emulator -avd <avd_name>
   ```
   例如：
   ```bash
   emulator -avd Pixel_3a_API_30_x86
   ```

4. **在已启动的模拟器上运行应用：**
   ```bash
   flutter run
   ```

## 快速启动

直接运行应用（会自动启动可用的模拟器）：
```bash
flutter run
```

选择特定设备运行：
```bash
flutter devices  # 查看可用设备
flutter run -d <device_id>
```
