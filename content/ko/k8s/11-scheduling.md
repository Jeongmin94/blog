---
title: "11 Scheduling"
date: 2022-08-13T11:51:57+09:00
draft: true
tags:
tags:
- scheduling
categories:
- k8s
---
쿠버네티스에서 제공하는 다양한 스케줄링 방법을 알아본다.
<!--more-->

# 고급 스케줄링

쿠버네티스가 Pod의 기본적인 스케줄링은 채임지지만 사용자가 좀 더 상세하게 프로세스를 스케줄링할 수 있다. 이를 통해 어플리케이션의 고가용성 확보를 위한 자동 확장, Pod 상세 스케줄링 등을 수행할 수 있다.

## 1. 고가용성 확보 - Pod 레벨

ReplicaSet, Deployment 리소스의 `replica` 프로퍼티를 사용하면 일정 범위 안의 트래픽에 대해서는 서비스 가용성을 유지할 수 있다. 하지만 replica의 수가 정적으로 고정되어 있기 때문에 범위를 넘어서는 트래픽에 대해서는 한계를 가진다.

하나의 컨테이너에서 처리할 수 있는 양을 넘어서는 트래픽이 들어온다면 어떻게 해야할까? 기본적으로 컨테이너의 성능을 높이거나 같은 역할을 하는 컨테이너를 늘리는 방법으로 문제를 해결할 수 있을 것이다. 성능을 높이는 방법은 하드웨어라는 제약 사항이 있기 때문에 한계가 있지만, 컨테이너를 늘리는 방법은 관리만 잘해준다면 비교적 적은 비용으로 더 많은 트래픽을 처리할 수 있다는 장점을 가진다.

그렇다면 쿠버네티스에서는 어떤 방식의 확장이 더 효율적일까? 기본적으로 쿠버네티스는 Pod을 가축처럼 다룬다. 특정 Pod이 정상적으로 작동하지 않는다면, 쿠버네티스에서는 이를 대체하는 새로운 Pod을 만들어 사용할 수 있도록 만들어 준다. 쿠버네티스가 점점 더 늘어나는 컨테이너를 효과적으로 관리하기 위해 등장한만큼, 당연하게도 수평적 확장에 대한 방법도 제공해주고 있다. 바로 HorizontalPodAutoScaler(hpa)다. hpa 리소스는 Pod의 개수를 수평적으로 확장시켜준다.

hpa는 metrics-server라는 컴포넌트를 사용한다. metrics-server는 Pod의 리소스 사용량을 모니터링하는 서버인데, 이것을 통해 일정 수준의 임계값을 넘으면 replica의 개수를 동적으로 조절하여 Pod의 개수를 늘려주게 된다. 또한, 임계값 아래로 요청량이 내려가면 Pod을 줄이기도 한다.


### metrics server 설치

> https://github.com/kubernetes-sigs/metrics-server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl get pod -nkube-system
NAME                                     READY   STATUS    RESTARTS         AGE
metrics-server-678f4bf65b-k24dl          0/1     Running   0                3m49s
```

```
# 리소스 사용량을 모니터링할 Pod를 하나 생성합니다.
kubectl run mynginx --image nginx

# Pod별 리소스 사용량을 확인합니다.
kubectl top pod
# NAME        CPU(cores)   MEMORY(bytes)
# mynginx     0m           2Mi

# Node별 리소스 사용량을 확인합니다.
kubectl top node
# NAME      CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# master    57m          2%     1846Mi          46%
# worker    43m          2%      970Mi          24%

kubectl delete pod mynginx
# pod/mynginx deleted
```