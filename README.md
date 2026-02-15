# After Party Game - Flutter版

React版をFlutter/Dartに変換したバージョンです。

## セットアップ

1. Flutter SDKのインストール（https://flutter.dev/）

2. 依存関係のインストール
```bash
flutter pub get
```

3. Firebaseの設定
- Firebase Consoleでプロジェクトを作成
- FlutterアプリをFirebaseプロジェクトに追加
- `google-services.json` (Android) と `GoogleService-Info.plist` (iOS) を配置

4. 実行
```bash
flutter run
```

## ビルド

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

### Web
```bash
flutter build web
```

## 主な機能

- ルーム作成・参加
- リアルタイムマルチプレイヤー
- QRコード共有
- カスタマイズ可能なチーム数・ルール
- ブロック積み上げゲーム

## ファイル構成

```
lib/
├── main.dart                    # エントリーポイント
├── services/
│   └── game_service.dart        # Firebase連携・ゲームロジック
├── screens/
│   ├── start_screen.dart        # スタート画面
│   ├── create_room_screen.dart  # ルーム作成
│   ├── join_room_screen.dart    # ルーム参加
│   ├── host_waiting_screen.dart # ホスト待機
│   └── player_register_screen.dart # プレイヤー登録
└── widgets/
    └── (共通ウィジェット)
```

## 注意事項

- Firebaseの設定は各自で行ってください
- iOS/Androidでテストする場合は実機またはエミュレータが必要です
- Webで動作させる場合はCORSの設定が必要な場合があります
