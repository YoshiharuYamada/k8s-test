# Kubernetes入門

目的kubeadmを用いてKubernetes環境構築して、基本的なコマンド等の理解

## 前提条件

- ホストPC：メモリ16GB、ディスク50GB
- VirtualBox
- Vagrant
  - vagrant-hostmanager プラグイン(vagrant plugin install vagrant-hostmanager)
  - vagrant-disksize プラグイン(vagrant plugin install vagrant-disksize)

## VM構成

- ホスト
  - IP 172.16.0.1 (ホストオンリーアダプターのNIC)
- Kubernetes master node 1台
  - CPU 2、メモリ 2GB、ディスク 20GB
  - IP 172.16.0.10 (ホストオンリーアダプターのNIC)
  - ホスト名 kube-master
- Kubernetes worker node 3台
  - CPU 2、メモリ 1GB、ディスク 20GB
  - IP 172.16.0.11 〜 172.16.0.13 (ホストオンリーアダプターのNIC)
  - ホスト名 kube-worker1 〜 kube-worker3
- Docker Registry 1台
  - CPU 1、メモリ 1GB、ディスク 10GB
  - IP 172.16.0.30 (ホストオンリーアダプターのNIC)
  - ホスト名 docker-registry

## Vagrant

- kube-master、kube-worker1〜3は、KubernetesパッケージインストールまでVagrantで設定
- docker-registryは、サンプルアプリのbuildとpushまでをVagrantで設定

### VM起動

```sh
$ vagrant up
```

### VM停止

```sh
$ vagrant halt
```

### VM破棄

```sh
$ vagrant destroy
```

## Kubernetesクラスタ構築

### マスターノード構築

```sh
$ vagrant ssh kube-master
$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=172.16.0.10
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
$ kubectl apply -f /vagrant/install/flannel/kube-flannel.yml
$ kubectl apply -f /vagrant/install/metallb/metallb.yaml
$ kubectl apply -f /vagrant/install/metallb/metallb-layer2-config.yml
$ kubectl apply -f /vagrant/install/ingress-nginx/mandatory.yaml
$ kubectl apply -f /vagrant/install/ingress-nginx/service-loadbalancer.yaml
$ kubectl apply -f /vagrant/install/metrics/
$ kubectl apply -f /vagrant/install/rook/operator.yaml
$ kubectl apply -f /vagrant/install/rook/cluster.yaml
$ kubectl apply -f /vagrant/install/rook/storageclass.yaml
```

- /etc/kubernetes/admin.conf
  - 構築したKubernetesクラスタの認証情報
- flannel
  - CoreOS製の複数のコンテナ間通信するためのネットワークプラグイン
  - ベンダー実装のためKubernetes本体にネットワークの設定は含まれない
  - kube-flannel.ymlのダウンロード元
    - https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
- metallb
  - Google製のロードバランサープラグイン
  - Kubernetes本体にロードバランサーの設定はできるが(External IPの付与は、ベンダー実装)
  - metallb.yamlのダウンロード元
    - https://github.com/google/metallb/raw/v0.7.3/manifests/metallb.yaml
  - LBが発行するExternal IPの範囲を172.16.0.50-172.16.0.99と定義
- ingress-nginx
  - Kubernetes製のIngressプラグイン
  - ベンダー実装のためKubernetes本体にIngressの設定は含まれない
  - mandatory.yamlのダウンロード元
    - https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.22.0/deploy/mandatory.yaml
- metrics-server
  - Kubernetes製のメトリクスプラグイン(kubectl topコマンドで必要)
  - ベンダー実装のためKubernetes本体にメトリクスの設定は含まれない
  - ダウンロード元
    - https://github.com/kubernetes-incubator/metrics-server/tree/92d8412788e27ee669d38f21f20bad5342211884/deploy/1.8%2B
- rook
  - Rook製のストレージプラグイン
  - ベンダー実装のためKubernetes本体にストレージの設定は含まれない
  - operator.yaml、cluster.yaml、storageclass.yamlのダウンロード元
    - https://github.com/rook/rook/tree/v0.9.1/cluster/examples/kubernetes/ceph

### ワーカーノード構築

kube-worker1でのコマンド、kube-worker2、kube-worker3は、sshホスト名違い

```sh
$ vagrant ssh kube-worker1
$ sudo kubeadm join 172.16.0.10:6443 --token xxx --discovery-token-ca-cert-hash sha256:yyy
```

- xxx、yyyは、マスター構築後、標準出力される値

## コマンド

kube-masterにSSHでログインしている前提

### kubectl

#### 一覧系

```sh
$ kubectl get リソース名 [-o wide] [--all-namespaces]
```

主なリソース名
nodes、pods、deployments、services(svc)、jobs、pvc、configmaps、secrets、ingress

#### 詳細系

```sh
$ kubectl describe リソース名/name [--all-namespaces]
```

#### オブジェクト登録、差分反映

```sh
$ kubectl apply -f ファイル
```

#### オブジェクト削除

```sh
$ kubectl delete -f ファイル
```

#### リソース確認

- Node

```sh
$ kubectl top node
```

- Pod

```sh
$ kubectl top pod [--all-namespaces]
```

#### コンテナログイン

```sh
$ kubectl exec -it Pod名 [-c コンテナ名] sh|bash
```

### stern

ログ取得コマンド

```sh
$ stern "Pod名の部分文字列" [-c コンテナ名]
```

例

```sh
$ stern "app-deploy" -c puma
```

## デプロイ

kube-masterにSSHでログインしている前提

### MySQL

```sh
$ kubectl apply -f /vagrant/deploy/mysql/mysql-volume-claim.yml
$ kubectl apply -f /vagrant/deploy/mysql/mysql-configmap.yml
$ kubectl apply -f /vagrant/deploy/mysql/mysql-secret.yml
$ kubectl apply -f /vagrant/deploy/mysql/mysql-deployment.yml
$ kubectl apply -f /vagrant/deploy/mysql/mysql-service.yml
```

### App

```sh
$ kubectl apply -f /vagrant/deploy/app/app-secret.yml
$ kubectl apply -f /vagrant/deploy/app/app-configmap-nginx.yml
$ kubectl apply -f /vagrant/deploy/app/app-configmap-puma.yml
$ kubectl apply -f /vagrant/deploy/app/app-job-migrate.yml
$ kubectl apply -f /vagrant/deploy/app/app-deployment.yml
$ kubectl apply -f /vagrant/deploy/app/app-service.yml
$ kubectl apply -f /vagrant/deploy/app/app-ingress.yml
```

ホストOSのhostsファイルに以下を追加し、ブラウザでアクセス

```
172.16.0.50 sample.example.com
```

設定ファイル変更後の反映

```sh
$ kubectl set env deploy/app-deployment RELOAD_DATE="$(date)"
```

## Kubernetes Webダッシュボード

kube-masterにSSHでログインしている前提

```sh
$ kubectl apply -f /vagrant/install/dashboard/kubernetes-dashboard.yaml
$ kubectl apply -f /vagrant/install/dashboard/service-account.yaml
$ kubectl apply -f /vagrant/install/dashboard/cluster-role-binding.yaml
```

- dashboard
  - Kubernetes製のWebダッシュボード
  - kubernetes-dashboard.yamlのダウンロード元
    - https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

以下のコマンドで出力されるtokenを控える

```sh
$ kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

以下のコマンドで出力される`443:xxx/TCP`のxxxを控える

```sh
$ kubectl get svc kubernetes-dashboard -n kube-system
```

プラウザで、`https://172.16.0.10:xxx/`にアクセスして、トークンをチェックして、控えたtokenでサインイン
