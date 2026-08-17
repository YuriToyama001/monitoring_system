# Monitoring System

このリポジトリは、Linux環境向けのシンプルな監視シェルスクリプト群をまとめたものです。
各スクリプトは `monitor_all.conf` から設定値を読み込み、CPU、メモリ、ネットワーク、外部ノードなどの状態をチェックします。

## 目的

- CPU使用率の監視
- メモリ使用率の監視
- ネットワークインターフェース状態の監視
- NICトラフィック監視
- 外部ノードへの疎通確認
- 監視結果の通知（Redis連携を想定）

## 構成

- `monitor_all.sh` - すべての監視スクリプトを順番に実行する統合ランチャー
- `monitor_all.conf` - 監視スクリプト共通の設定ファイル
- `monitor_common.sh` - 各スクリプトで使用される共通関数
- `cpu/monitor_cpu.sh` - CPU監視ラッパー（`cpu/monitor_cpu_usage.sh` / `cpu/monitor_cpu_temp.sh` を実行）
- `cpu/monitor_cpu_usage.sh` - CPU使用率チェック
- `cpu/monitor_cpu_temp.sh` - CPU温度チェック
- `memory/monitor_memory.sh` - メモリ監視ラッパー（`memory/monitor_memory_usage.sh` を実行）
- `memory/monitor_memory_usage.sh` - メモリ使用率チェック
- `network/monitor_network.sh` - ネットワーク監視ラッパー（`network/monitor_network_status.sh` / `network/monitor_network_traffic.sh` を実行）
- `network/monitor_network_status.sh` - ネットワークインターフェース状態チェック
- `network/monitor_network_traffic.sh` - ネットワークトラフィックチェック
- `network/monitor_network_gateway.sh` - インターフェースに設定されたデフォルトゲートウェイへの疎通チェック
- `external_node/monitor_external_node.sh` - 外部ホストへのPing疎通チェック
- `external_node/monitor_poeye_node.sh` - PoEye外部ノードの監視チェック
- `notify/notify_dispatch.sh` - 通知入口のラッパー
- `notify/notify_redis.sh` - 通知処理（Redis連携を想定）
- `notify/notify_dummy.sh` - ダミー通知（テスト用）
- `log_output/log_output.sh` - ログ出力専用機能
- `log_output/log_output_dispatch.sh` - ログ出力ディスパッチャー
- `log_output/syslog_output.sh` - syslog出力機能

## 事前準備

1. Bash が利用可能な Linux 環境を用意します。
2. `monitor_all.sh` および各スクリプトに実行権限を付与します。

```bash
chmod +x monitor_all.sh monitor_common.sh \
  cpu/monitor_cpu.sh cpu/monitor_cpu_usage.sh cpu/monitor_cpu_temp.sh \
  memory/monitor_memory.sh memory/monitor_memory_usage.sh \
  network/monitor_network.sh network/monitor_network_status.sh network/monitor_network_traffic.sh network/monitor_network_gateway.sh \
  external_node/monitor_external_node.sh external_node/monitor_poeye_node.sh \
  notify/notify_dispatch.sh notify/notify_redis.sh notify/notify_dummy.sh \
  log_output/log_output.sh log_output/log_output_dispatch.sh log_output/syslog_output.sh
```

3. `monitor_all.conf` の設定を環境に合わせて編集します。

## 設定項目 (`monitor_all.conf`)

- `INTERFACE` - 監視対象ネットワークインターフェース名（例: `eth0`）
- `CPU_THRESHOLD` - CPU使用率警告閾値（%）
- `CPU_TEMP_THRESHOLD` - CPU温度警告閾値（°C）
- `MEMORY_THRESHOLD` - メモリ警告閾値（%）
- `NETWORK_TRAFFIC_THRESHOLD` - ネットワークトラフィック警告閾値（NIC速度に対する%）
- `NODE_HOST` - 外部ノード疎通確認先のホスト
- `INTERVAL` - 一部スクリプトで使用するチェック間隔（秒）
- `REDIS_HOST` - Redis通知先ホスト
- `REDIS_PORT` - Redis通知先ポート

## 実行方法

```bash
./monitor_all.sh
```

個別に実行する場合:

```bash
./cpu/monitor_cpu.sh
./memory/monitor_memory.sh
./network/monitor_network.sh
./external_node/monitor_external_node.sh
```

## 通知について

`notify/notify_dispatch.sh` は通知用の共通入口です。以下の通知方式から選択できます：

- `notify/notify_redis.sh` - 監視結果をRedisへ送信（本番環境向け）
- `notify/notify_dummy.sh` - ダミー通知処理（テスト・デバッグ用）

`log_output/log_output.sh` は通知機能とは独立したログ出力機能です。通知とは別に利用できます。
同様に、`log_output/log_output_dispatch.sh` および `log_output/syslog_output.sh` でログ出力をカスタマイズできます。

Redis連携を有効にするには、`notify/notify_redis.sh` 内の `redis-cli` コマンドのコメントを解除し、必要に応じて `REDIS_HOST` / `REDIS_PORT` を設定してください。

## 注意点

- スクリプトは `/proc` および `/sys/class/net` を参照するため、Linuxカーネル環境での実行を前提としています。
- `monitor_network_traffic.sh` のトラフィック計算は、指定インターバル単位でのバイト差分から概算Mbpsを算出します。

## 拡張

- `notify/notify_redis.sh` でRedis通知を有効化
- `notify/notify_dummy.sh` をテンプレートにして独自の通知方式を実装
- `log_output/log_output.sh` / `log_output_dispatch.sh` / `syslog_output.sh` でログ出力をカスタマイズ
- `external_node/monitor_poeye_node.sh` でPoEye等外部ノードの監視を拡張
- `external_node/monitor_external_node.sh` にHTTPヘルスチェックなどの追加監視
- cronやsystemdタイマーで定期実行

## systemdで定期実行する

リポジトリ直下に `monitoring.service.sample` と `monitoring.timer.sample` を用意しています。Linuxのsystemd環境で次のように配置・有効化できます。

```bash
sudo cp monitoring.service.sample /etc/systemd/system/monitoring.service
sudo cp monitoring.timer.sample /etc/systemd/system/monitoring.timer
sudo systemctl daemon-reload
sudo systemctl enable --now monitoring.timer
```

確認コマンド:

```bash
sudo systemctl status monitoring.timer
sudo systemctl list-timers --all | grep monitoring
sudo journalctl -u monitoring.service -n 20
```
