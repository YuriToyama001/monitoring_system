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
- `cpu/monitor_cpu.sh` - CPU監視ラッパー（`cpu/monitor_cpu_usage.sh` / `cpu/monitor_cpu_temp.sh` を実行）
- `cpu/monitor_cpu_usage.sh` - CPU使用率チェック
- `cpu/monitor_cpu_temp.sh` - CPU温度チェック
- `memory/monitor_memory.sh` - メモリ使用率チェック
- `network/monitor_network.sh` - ネットワーク監視ラッパー（`network/monitor_network_status.sh` / `network/monitor_network_traffic.sh` を実行）
- `network/monitor_network_status.sh` - ネットワークインターフェース状態チェック
- `network/monitor_network_traffic.sh` - ネットワークトラフィックチェック
- `external_node/monitor_external_node.sh` - 外部ホストへのPing疎通チェック
- `notify/notify_redis.sh` - 通知処理（現在はRedisコマンド部分がコメントアウトされ、標準出力へ出力）
- `old/` - 旧バージョンのスクリプトを保存

## 事前準備

1. Bash が利用可能な Linux 環境を用意します。
2. `monitor_all.sh` および各スクリプトに実行権限を付与します。

```bash
chmod +x monitor_all.sh cpu/monitor_cpu.sh cpu/monitor_cpu_usage.sh cpu/monitor_cpu_temp.sh memory/monitor_memory.sh network/monitor_network.sh network/monitor_network_status.sh network/monitor_network_traffic.sh external_node/monitor_external_node.sh notify/notify_redis.sh
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

`notify/notify_redis.sh` は監視結果をRedisへ送信する想定です。現在はRedisコマンドがコメントアウトされており、代わりに標準出力へ結果を出力します。

Redis連携を有効にするには、`notify/notify_redis.sh` 内の `redis-cli` コマンドのコメントを解除し、必要に応じて `REDIS_HOST` / `REDIS_PORT` を設定してください。

## 注意点

- スクリプトは `/proc` および `/sys/class/net` を参照するため、Linuxカーネル環境での実行を前提としています。
- `monitor_network_traffic.sh` のトラフィック計算は、指定インターバル単位でのバイト差分から概算Mbpsを算出します。

## 拡張

- `notify/notify_redis.sh` でRedis通知を有効化
- `external_node/monitor_external_node.sh` にHTTPヘルスチェックなどの追加監視
- cronやsystemdタイマーで定期実行
