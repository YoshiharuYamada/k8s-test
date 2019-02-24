# Kubernetes Webダッシュボード

kube-masterにSSHでログインしている前提

## 設定

```sh
$ kubectl apply -f /vagrant/install/dashboard/kubernetes-dashboard.yaml
$ kubectl apply -f /vagrant/install/dashboard/service-account.yaml
$ kubectl apply -f /vagrant/install/dashboard/cluster-role-binding.yaml
```

- dashboard
  - Kubernetes製のWebダッシュボード
  - kubernetes-dashboard.yamlのダウンロード元
    - https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

## サインイン

以下のコマンドで出力されるtokenを控える

```sh
$ kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

以下のコマンドで出力される`443:xxx/TCP`のxxxを控える

```sh
$ kubectl get svc kubernetes-dashboard -n kube-system
```

プラウザで、`https://172.16.0.10:xxx/`にアクセスして、トークンをチェックして、控えたtokenでサインイン
