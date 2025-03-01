# Jump Hachi

一個靈感來自 “Jump King” 的簡易平台動作遊戲。本次左業目標是參考 “Jump King” 用AI打造一個遊戲機制簡單，考驗玩家操作的小遊戲。

## 功能

- 使用吉伊卡哇素材、音效
- 考驗玩家技術的遊戲機制
- 計時顯示完成時間

## 安裝

1. 架設 flutter 環境，並將 flutter 加到 PATH。
2. （optional）安裝 android-studio 和設定模擬器。
3. 複製此專案

```
git clone https://github.com/DrifterAldvvyn/JumpHachi.git
```

4. 進入專案目錄 

```
cd JumpHachi
```

5. 安裝依賴（flame, flame_audio）

```
flutter pub get
```

6. 執行

```
flutter run
```

## 遊玩方法

1. 使用底部介面操控小八
2. 小八能左右移動，朝面對方向跳躍
3. 按住跳躍鍵能蓄力跳更高
4. 目標是跳到黃色平台拯救吉伊
5. 到達終點會顯示花的時間，嘗試以最快速度到達終點吧！
