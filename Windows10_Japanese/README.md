# Windows 10の日本語化イメージを作成します
※https://github.com/NakayamaKento/azureimagebuilder/tree/main/AVD をほぼそのまま使わせてもらってます。

ファイルの説明

- AIBscript.ps1
    - Image Builderテンプレートを実行するためのすべてのリソースをデプロイします
- Installlanguagepack.ps1
    - 日本語化するためのPowerShellスクリプトです。Image Builderテンプレートが参照します
- aibRoleImageCreation.json
    - image builderを実行するためのカスタムロールです。AIBscript.ps1で参照します
- localize.json
    - image builderの本体です。ここに記載のある内容に沿って、イメージの作成が行われます


AIBscript.ps1 の実行内容
-
- 必要なリソースプロバイダー、PowerShellモジュールの確認
- リソースグループの作成
- マネージドIDの作成
- カスタムロールの作成（作成完了後、利用できるまで時間がかかるため待機時間を設けています）
- マネージドIDにカスタムロールを割り当て
- Azure Compute Galleryの作成
- image builderテンプレートの作成
