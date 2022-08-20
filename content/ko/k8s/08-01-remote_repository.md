---
title: "08-01 helm remote repository"
date: 2022-07-25T20:18:47+09:00
draft: true
tags:
- helm
categories:
- k8s
---
helm을 사용할 때의 장점인 원격 레포지토리에 대해서 알아본다.
<!--more-->


# 원격 레포지토리
helm을 사용하면 외부에서 잘 구축된 어플리케이션을 매우 쉽게 가져올 수 있다. helm만 잘 사용해도 쿠버네티스 생태계에서 지원하는 다양하고 강력한 어플리케이션을 활용할 수 있기 때문이다.

따라서 helm을 잘 활용할 수 있도록 helm 생성에 사용되는 chart의 원격 저장소인 레포지토리가 존재한다. 레포지토리는 여러 chart를 한 곳에 묶어 보관해놓은 저장소로, 온라인에 존재하는 원격 레포지토리를 추가하여 chart를 로컬 쿠버네티스 클러스터에 설치할 수 있다.

## 1. 레포지토리 추가

원격 레포지토리에 있는 `stable`이라는 레포지토리를 추가한다.

```bash
# appscode repo 추가
helm repo add appscode https://charts.appscode.com/stable/
# "appscode" has been added to your repositories
```

## 2. 레포지토리 업데이트

추가한 레포지토리의 인덱스 정보를 최신 버전으로 업데이트한다.

```bash
# repo update
helm repo update
# Hang tight while we grab the latest from your chart repositories...
# ...Successfully got an update from the "appscode" chart repository
# Update Complete. ⎈ Happy Helming!⎈
```

## 3. 레포지토리 조회

현재 등록된 레포지토리 리스트를 확인한다. `appscode` 레포지토리만 등록했기 때문에 1개만 나오는 것이 정상이다.

```bash
# 현재 등록된 repo 리스트
helm repo list
# NAME            URL
# appscode        https://charts.appscode.com/stable/
```

## 4. 레포지토리 내 chart 조회

`appscode` 레포지토리에 저장된 chart 리스트를 확인한다.

```bash
# appscode 레포 안의 chart 리스트
helm search repo appscode
# NAME                                                    CHART VERSION   APP VERSION     DESCRIPTION
# appscode/accounts-ui                                    v2022.06.14     v2022.06.09.1   A Helm chart for Kubernetes
# appscode/ace                                            v2022.06.14     v2022.06.09.1   A Helm chart for Kubernetes
# appscode/application-crds                               v0.8.3          v0.8.3          Kubernetes Application CRDs
# appscode/auditor                                        v2022.06.14     v0.0.1          Kubernetes Auditor by AppsCode
# ...

helm search repo appscode/accounts-ui
# NAME                    CHART VERSION   APP VERSION     DESCRIPTION
# appscode/accounts-ui    v2022.06.14     v2022.06.09.1   A Helm chart for Kubernetes
```

> 다양한 레포지토리를 확인할 수 있는 사이트
> https://artifacthub.io/

## 5. 레포지토리의 chart 설치

`appscode` 레포지토리에 있는 수많은 chart 중에서 자신이 원하는 chart를 선택해서 설치할 수 있다. 레포지토리를 등록했기 때문에 로컬 디렉토리에 chart가 없더라도 원격 레포지토리에 있는 chart를 설치할 수 있는 것이다. 이때 몇 가지 옵션을 함께 지정할 수 있다.

- `--version` : chart의 버전을 지정한다. `Chart.yaml` 파일 안에 있는 version 정보를 참조하게 된다.
- `--set` : 해당 옵션으로 `values.yaml` 설정값을 동적으로 설정할 수 있다.
- `--namespace` : chart가 설치될 네임스페이스를 지정한다.

```bash
# appscode/accounts-ui 설치
helm install au appscode/accounts-ui \
    --set service.port=8080 \
    --namespace default 

# NAME: au
# LAST DEPLOYED: Mon Jul 25 20:39:54 2022
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# Application deployed. Find pods by running the following command:

# kubectl get pods -n default -l "app.kubernetes.io/name=accounts-ui,app.kubernetes.io/instance=au"

kubectl get pod
# NAME                              READY   STATUS    RESTARTS   AGE
# au-accounts-ui-74b87c4969-c6852   0/1     Pending   0          38s

kubectl get svc
# NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
# au-accounts-ui   ClusterIP   10.100.232.207   <none>        8080/TCP   69s
# kubernetes       ClusterIP   10.96.0.1        <none>        443/TCP    12d
```

이렇게 로컬 쿠버네티스 클러스터에 저장되어 있지 않은 chart, 소프트웨어라도 helm 원격 레포지토리를 추가하고 `helm install` 명령어를 사용하면 외부에서 구축된 어플리케이션을 손쉽게 사용할 수 있게 된다.

## 6. chart fetch

레포지토리의 chart를 원격에서 바로 설치할 수도 있지만, 로컬에 다운로드해서 설치할 수도 있다. 사용자가 세부적으로 설정값들을 수정하고 어플리케이션을 설치하고 싶을 때 `fetch` 명령을 이용해서 먼저 chart를 다운로드 할 수 있다. 이렇게 다운로드된 chart는 `tar`로 묶여 있는 상태가 되며, `--untar` 옵션을 사용하면 풀어진 상태로 저장이 가능하다.

```bash
helm fetch --untar appscode/accounts-ui
```

이렇게 다운로드 받은 chart의 `values.yaml`을 수정하고, 다시 `helm install` 명령어를 사용하면 원하는 설정값을 가진 새로운 chart를 실행할 수 있게 된다.

## END

helm 패키지 매니저는 쿠버네티스를 사용할 때 도움을 주는 강력한 툴이다. helm은 쿠버네티스의 기능을 풍성하게 만들어주고, 복잡한 어플리케이션도 손쉽게 구축할 수 있게 된다.

```bash
# clean up
helm delete au
```