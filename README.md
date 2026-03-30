# BPIM2(App)

beatmania IIDX の スコア管理 Web アプリ「[BPIM2](https://bpi2.poyashi.me)」をネイティブアプリとして利用するための Flutter ラッパーです。
独自機能として、eAMUSEMENT GATE からスコアデータを自動取得し、BPIM2 へ直接インポートする機能を備えます。

## 機能

- BPI Manager 2 の全機能をネイティブアプリとして利用
- eAMUSEMENT GATE からスコアを自動取得してワンタップでインポート（右下の更新ボタンから実行）
  - eAMUSEMENT プレミアムに加入済みの場合、公式CSVを使用してスコアを取り込みます
  - eAMUSEMENT プレミアムに加入していない場合、[IIDX-Scraping-Bookmarklet](https://github.com/BPIManager/IIDX-Scraping-Bookmarklet)を使用してスコアを集計し取り込みます。(1分程度かかり、ミスカウントやプレイ時間は記録されません)

## ダウンロード

最新のビルド済みパッケージは [Releases](../../releases/latest) からダウンロードできます。

| プラットフォーム | ファイル                    |
| ---------------- | --------------------------- |
| Android          | `bpim2-flutter-android.apk` |
| Windows          | `bpim2-flutter-windows.zip` |

> **注意**:  
> これらは野良アプリです。  
> セキュリティ上の懸念がある場合は、後述の手順に従ってご自身でビルドしてください。  
> iOS端末持ってないのでリリースファイルには含まれませんが、自己ビルドで使おうと思えば使えるのではないかと思います。

---

## セキュリティに関する重要事項

**このアプリをインストール・使用する前に必ずお読みください。**

### eAMUSEMENT スコア自動取得機能について

- 本アプリは `flutter_inappwebview` を使用して **eAMUSEMENT GATE** (`p.eagate.573.jp`) に WebView でアクセスし、スコアダウンロードページから CSV データを取得します。
- スコア取得時に `assets/scraper.js`（ をベースとした JavaScript）を eAMUSEMENT GATE のページ上で実行します。
- **eAMUSEMENT のログイン情報（ID・パスワード）は当アプリのサーバーには一切送信されません。** ログインは eAMUSEMENT 公式ページ上で直接行われます。
- ただし、理論的にはID・パスワードを窃取しようと思えばできる仕組みです。
- ソースコードはすべて公開されています。不安な場合はコードをソースコードを確認した上で、ご自身でビルドしたものをご利用ください。
  - [BPIManager/BPIM2-Flutter](https://github.com/BPIManager/BPIM2-Flutter)
  - [BPIManager/IIDX-Scraping-Bookmarklet](https://github.com/BPIManager/IIDX-Scraping-Bookmarklet)

### Android APK の署名について

- Releases で配布している APK は デバッグ証明書で署名されています（Google Play には公開していないため）。
- **信頼性が気になる場合は、ご自身でビルドして使用することを推奨します。**

### 免責事項

- eAMUSEMENT GATE の仕様変更により、スコア取得機能が突然動作しなくなる場合があります。
- 本ツールの使用による、各自の eAMUSEMENT アカウントへのいかなる影響についても、開発者は責任を負いません。
- 利用は**自己責任**でお願いします。

---

## 自分でビルドする

### 必要なもの

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.24 以上（`flutter --version` で確認）
- **Android APK**: Android SDK（Android Studio 推奨）
- **Windows EXE**: Windows 10/11 + Visual Studio 2022（C++ ビルドツール含む）

### 手順

```bash
# リポジトリのクローン
git clone https://github.com/BPIManager/BPIM2-Flutter.git
cd BPIM2-Flutter

# 依存パッケージのインストール
flutter pub get

# アイコン・スプラッシュ生成（初回のみ）
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

#### Android APK

```bash
flutter build apk --release
# 出力: build/app/outputs/flutter-apk/app-release.apk
```

リリース用に独自の署名を行う場合は [Flutter 公式ドキュメント](https://docs.flutter.dev/deployment/android#signing-the-app) を参照してください。

#### Windows

```bash
flutter build windows --release
# 出力: build/windows/x64/runner/Release/
```

ZIP にまとめる場合：

```powershell
Compress-Archive -Path build/windows/x64/runner/Release/* -DestinationPath bpim2-flutter-windows.zip
```

#### 開発用サーバー起動

```bash
flutter run   # 接続中のデバイス / エミュレータで起動
```

---

## 技術スタック

| 用途                   | パッケージ                |
| ---------------------- | ------------------------- |
| WebView                | flutter_inappwebview      |
| 設定の永続化           | shared_preferences        |
| 外部リンクの起動       | url_launcher              |
| アイコン生成           | flutter_launcher_icons    |
| スプラッシュ画面       | flutter_native_splash     |

---

## ライセンス

[MIT License](LICENSE)

本アプリは BPIM2 (https://bpi2.poyashi.me) の公式クライアントです。
beatmania IIDX および eAMUSEMENT はコナミアミューズメント株式会社の商標です。
本アプリは beatmania IIDX および KONAMI グループ各社とは一切無関係の個人が作成したファンメイドツールです。
