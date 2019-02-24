# Helm

主な構成要素はhelm、tiller、Repositoryの3つ

- Helm(クライアントコマンド)
  - ローカルのChart(k8nのYAMLファイル群と設定ファイル)開発
  - リポジトリの管理(使用しない)
  - Tillerサーバとの通信
    - リソース作成・削除・情報取得などを要求
- Tiller(k8n側クラスタ内のリソースとして定義され動作するサーバ)
  - Helmクライアントからのリクエスト受付
    - リソース作成・削除・情報取得などの操作
- Repository
  - 仕事でChartを公開して使用することがないので割愛

## 設定

kube-masterにSSHでログインしている前提

- オートコンプリート

```sh
$ echo "source <(helm completion bash)" >> ~/.bashrc
$ exec $SHELL -l
```

- Helm初期化

```sh
$ kubectl apply -f /vagrant/install/helm/service-account.yaml
$ kubectl apply -f /vagrant/install/helm/cluster-role-binding.yaml
$ helm init --service-account=tiller --wait
```

## helmコマンド

- Chart雛形作成

```sh
$ helm create ディレクトリ
```

- Chart内容をレンダー

```sh
$ helm template [--debug] [--name=リリース名] [--namespace=ネームスペース] [--values=values.yamlをオーバーライドするyaml] Chartディレクトリ
```


- リリース一覧

```sh
$ helm list [--all]
```

- デプロイ

```sh
$ helm upgrade リリース名 [--namespace=ネームスペース名] --install [--wait] [--values=values.yamlをオーバーライドするyaml] Chartィレクトリ
```

- 削除

```sh
$ helm delete リリース名 [--purge]
```

- ステータス

```sh
$ helm status リリース名
```

- 履歴

```sh
$ helm history リリース名
```

## デプロイの詳細

### オブジェクトの実行順序

- Namespace
- ResourceQuota
- LimitRange
- PodSecurityPolicy
- PodDisruptionBudget
- Secret
- ConfigMap
- StorageClass
- PersistentVolume
- PersistentVolumeClaim
- ServiceAccount
- CustomResourceDefinition
- ClusterRole
- ClusterRoleBinding
- Role
- RoleBinding
- Service
- DaemonSet
- Pod
- ReplicationController
- ReplicaSet
- Deployment
- StatefulSet
- Job
- CronJob
- Ingress
- APIService

### フック

- 前処理
  - pre-install: インストール時の前処理
  - pre-upgrade: アップグレード時の前処理
- 後処理
  - post-install: インストール時の後処理
  - post-upgrade: アップグレード時の後処理
- 実行順序
  - 重み付けで、実行順序を制御できる
  - 重み付けを定義しないとファイル名順ぽい(上記の実行順序でない)
- 削除ポリシー
  - hook-succeeded: フックが正常に実行された後にフックを削除
  - hook-failed: 実行中にフックが失敗した場合、フックを削除
  - before-hook-creation: 新しいフックが起動される前にTillerが前のフックを削除

## サンプルデプロイ

- Production用

```sh
$ helm upgrade mysql-prod --namespace=prod --install --wait /vagrant/chart/mysql/
$ helm upgrade redis-prod --namespace=prod --install --wait /vagrant/chart/redis/
$ helm upgrade app-prod --namespace=prod --install --wait /vagrant/chart/app/
```

- Staging用

```sh
$ helm upgrade mysql-staging --namespace=staging --install --wait /vagrant/chart/mysql/
$ helm upgrade redis-staging --namespace=staging --install --wait /vagrant/chart/redis/
$ helm upgrade app-staging --namespace=staging --install --wait --values=values-staging.yaml /vagrant/chart/app/
```

違いは、ネームスペースとFQDNとnginx、pumaのpod数  
ホストOSのhostsファイルに以下を追加し、ブラウザでアクセス

```
172.16.0.50 sample.example.com stg-sample.example.com
```

設定ファイル変更のみのデプロイでは、Deploymentオブジェクトの更新がかからないので以下で強制更新

```sh
$ kubectl -n ネームスペース set env deployment app-deployment-puma RELOAD_DATE="$(date)"
$ kubectl -n ネームスペース set env deployment app-deployment-sidekiq RELOAD_DATE="$(date)"
```
