---
title: "12 Managing Cluster"
date: 2022-08-20T20:13:09+09:00
draft: true
tags:
- managing cluster
categories:
- k8s
---
쿠버네티스의 클러스터를 효율적으로 운영 및 유지보수 하기 위한 방법들에 대해 알아본다.
<!--more-->

# 리소스 관리

쿠버네티스에서는 가상의 논리 클러스터인 네임 스페이스를 이용하여 리소스를 관리할 수 있게 해준다. 앞에서는 Pod의 resource 프로퍼티를 사용하여 리소스를 관리했는데, 쿠버네티스에서는 LimitRange, ResourceQuota라는 리소스 관리 담당 리소스가 존재한다.

일반적으로 쿠버네티스 사용자는 두 분류로 나눌 수 있다. 첫 번째는 일반 사용자이고, 다른 한 종류는 관리자이다.

일반 사용자는 자신이 개발한 어플리케이션을 쿠버네티스 플랫폼 위에 실행하는 역할을 가진다. 관리자는 쿠버네티스 클러스터 자체를 관리하고 필요한 물리 리소스를 제공하는 역할을 한다. 이 두 역할을 한 사람이 맡을 수도 있지만, 서로 다른 사람이 될 수도 있다.

이때, 클러스터 관리자가 일반 사용자에게 리소스 사용량을 제한하기 위해 사용하는 것이 LimitRange와 ResourceQuota 리소스다.

## 1. LimitRange

LimitRange 리소스는 두 가지 역할을 가지고 있다.

- 일반 사용자가 리소스 사용량 정의를 생략해도 자동으로 Pod의 리소스 사용량을 설정한다.
- 관리자가 설정한 최대 요청량을 일반 사용자가 넘지 못하게 제한한다.

한 마디로 LimitRange는 일반 사용자의 Pod 리소스 설정을 통제하는 리소스가 된다. 일반적으로 리소스에 대한 특별한 설정 없이 Pod를 만들면 제약 없이 무제한으로 노드의 전체 리소스를 사용할 수 있다.

```bash
# 일반적인 Pod 생성, Pod가 속한 노드의 리소스를 무제한으로 사용할 수 있다.
kubectl run mynginx --image nginx

kubectl get pod mynginx -oyaml | grep resources
# resources: {}
```

이런 경우에는 일반 사용자가 생성한 Pod가 노드의 전체 리소스를 고갈시킬 위험을 가지고 있다. 클러스터 관리자는 이에 대비하여 LimitRange 리소스를 특정 네임스페이스에 설정할 수 있다.

```yaml
# limit-range.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: limit-range
spec:
  limits:
  - default:
      cpu: 400m
      memory: 512Mi
    defaultRequest:
      cpu: 300m
      memory: 256Mi
    max:
      cpu: 600m
      memory: 600Mi
    min:
      cpu: 200m
      memory: 200Mi
    type: Container
```

- default : 일반 사용자가 resources 프로퍼티에 대한 설정을 하지 않는 경우 default 설정을 가져간다. limit 사용량을 의미한다.
- defaultRequest : resources 프로퍼티에 대한 설정을 하지 않는 경우 defaultRequest 설정값을 기본 요청 값으로 사용한다.
- max : 일반 사용자가 요청할 수 있는 최대치
- min : 일반 사용자가 요청할 수 있는 최소치

이제 default 네임스페이스에 위와 같은 LimitRange 리소스를 설정하고, 다시 Pod를 생성해서 LimitRange가 적용되었는지 살펴보자.

```bash
kubectl apply -f limit-range.yaml
# limitrange/limit-range created

kubectl run nginx-lr --image nginx
# pod/nginx-lr created

kubectl get pod nginx-lr -oyaml | grep -A 6 resources
#    resources:
#      limits:
#        cpu: 400m
#        memory: 512Mi
#      requests:
#        cpu: 300m
#        memory: 256Mi
```

`mynginx` Pod와는 다르게 resources 프로퍼티를 설정하지 않아도 LimitRange 리소스에서 지정한 설정값이 적용되어 있는 것을 확인할 수 있다. 만약, 사용자가 LimitRange를 벗어난 리소스를 요청한다면 어떻게 될까?

```yaml
# pod-exceed.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-exceed
spec:
  containers:
  - image: nginx
    name: nginx
    resources:
      limits:
        cpu: "700m"
        memory: "700Mi"
      requests:
        cpu: "300m"
        memory: "256Mi"
```
```bash
kubectl apply -f pod-exceed.yaml
# Error from server (Forbidden): error when creating "STDIN": pods 
# "pod-exceed" is forbidden: [maximum cpu usage per Container 
# is 600m, but limit is 700m, maximum memory usage per Container 
# is 600Mi, but limit is 700Mi]
```

일반 사용자가 LimitRange의 max 프로퍼티에서 설정한 설정값을 벗어난 limit을 설정하여 Pod 생성 에러가 발생한 것을 확인할 수 있다.

### clean up
```bash
kubectl delete limitrange limit-range
kubectl delete pod --all
```

## 2. ResourceQuota

LimitRange는 특정 네임스페이스 내의 개별 Pod 생성에 대해 관여했다면 ResourceQuota는 전체 네임스페이스에 대한 제약을 설정할 수 있다.

- LimitRange는 네임스페이스 내의 개별 Pod에 대한 제약조건이다. LimitRange를 만족하는 Pod가 여러개 존재한다고 하면, LimitRange 제약은 만족하지만 전체 노드의 리소스 고갈 위험은 여전히 존재한다.
- ResourceQuota는 이런 문제를 방지하고자 네임스페이스 전체에 대한 제약을 설정할 수 있게 만들어주는 리소스다.

따라서 ResourceQuota를 사용하게 되면 네임스페이스의 전체 총합에 대한 제약을 생성하는 것으로 이해할 수 있다.

```yaml
# res-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: res-quota
spec:
  hard:
    limits.cpu: 700m
    limits.memory: 800Mi
    requests.cpu: 500m
    requests.memory: 700Mi
```

- ResourceQuota에서 설정한 spec.hard 프로퍼티의 값들은 특정 네임스페이스가 가질 수 있는 총 cpu, memory 양을 의미한다.
- Pod 전체 총합이 cpu는 700m, memory는 800mi를 넘으면 안된다.
- 마찬가지로 cpu, memory에 대한 요청 총합이 각각 500m, 700mi를 넘으면 안된다.

이와 같은 ResourceQuota를 실행하고 ResourceQuota를 만족하는 Pod를 실행해보자.

```bash
# ResourceQuota 생성
kubectl apply -f res-quota.yaml
# resourcequota/res-quota created 

# Pod 생성 limit CPU 600m
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: rq-1
spec:
  containers:
  - image: nginx
    name: nginx
    resources:
      limits:
        cpu: "600m"
        memory: "600Mi"
      requests:
        cpu: "300m"
        memory: "300Mi"
EOF
# pod/rq-1 created
```

ResourceQuota를 실행하고 cpu, memory 제한이 600m, 600mi이고, 요청을 300m, 300mi를 하는 Pod를 실행했을 때 정상적으로 작동하는 것을 확인할 수 있다. 이 상태에서 `rq-1`과 동일한 스펙을 가진 다른 Pod를 실행시켜 보자.

```bash
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: rq-2
spec:
  containers:
  - image: nginx
    name: nginx
    resources:
      limits:
        cpu: "600m"
        memory: "600Mi"
      requests:
        cpu: "300m"
        memory: "300Mi"
EOF
# Error from server (Forbidden): error when creating "STDIN": 
# pods "rq-2" is forbidden: exceeded quota: res-quota, 
# requested: limits.cpu=600m,limits.memory=600Mi,requests.cpu=300m, 
# used: limits.cpu=600m,limits.memory=600Mi,requests.cpu=300m, 
# limited: limits.cpu=700m,limits
```

`rq-2`는 `rq-1`과 동일한 스펙을 가졌지만, Pod 생성에 실패한 것을 확인할 수 있다. 그 이뉴는 ResourceQuota를 통해 default 네임스페이스의 총합에 대한 제약을 걸었기 때문이다. `rq-1`과 `rq-2` 총합이 ResourceQuota에서 설정한 총합에 대한 제약을 넘어 에러가 발생한 것이다.

#### clean up

```bash
kubectl delete resourcequota res-quota
kubectl delete pod --all
```

# 노드 관리

Pod와 같은 리소스에 대한 관리뿐만 아니라 노드 자체에 대한 관리도 필요하다. 쿠버네티스에서는 특정 노드를 유지보수 상태로 전환하여 해당 노드에 대해서 새로운 Pod를 스케줄링하지 않게 만들 수 있다.

- cordon : 노드를 유지보수 모드로 전환
- uncordon : 유지보수가 완료된 노드의 정상화
- drain : 노드를 유지보수 모드로 전환하며, 기존의 Pod을 evict 시킴

## 1. cordon

쿠버네티스에서 특정 노드를 유지보수 모드로 전환하기 위해 cordon을 사용한다. 유지보수 모드가 된 노드에는 Pod이 출입할 수 없게 된다.

```bash
# 먼저 worker의 상태를 확인합니다.
kubectl get node worker -oyaml | grep spec -A 5
# spec:
#   podCIDR: 10.42.0.0/24
#   podCIDRs:
#   - 10.42.0.0/24
#   providerID: k3s://worker
# status:

# worker를 cordon시킵니다.
kubectl cordon worker
# node/worker cordoned

# 다시 worker의 상태를 확인합니다. taint가 설정된 것을 확인할 수 있고 unschedulable이 true로 설정되어 있습니다.
kubectl get node worker -oyaml | grep spec -A 10
# spec:
#   podCIDR: 10.42.0.0/24
#   podCIDRs:
#   - 10.42.0.0/24
#   providerID: k3s://worker
#   taints:
#   - effect: NoSchedule
#     key: node.kubernetes.io/unschedulable
#     timeAdded: "2020-04-04T11:04:48Z"
#   unschedulable: true
# status:

# worker의 상태를 확인합니다.
kubectl get node
# NAME     STATUS                    ROLES    AGE   VERSION
# master   Ready                     master   32d   v1.18.6+k3s1
# worker   Ready,SchedulingDisabled  worker   32d   v1.18.6+k3s1
```

이 상태에서 ReplicaSet을 이용하여 여러 Pod를 생성하면, 출입이 통제된 worker 노드에는 더 이상 Pod가 생성되지 않고 전부 마스터 노드에서 실행되게 된다.

```bash
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rs
spec:
  replicas: 5
  selector:
    matchLabels:
      run: rs
  template:
    metadata:
      labels:
        run: rs
    spec:
      containers:
      - name: nginx
        image: nginx
EOF

kubectl get pod -o wide
# NAME     READY   STATUS    RESTARTS   AGE    IP          NODE     ...
# rs-xxxx  1/1     Running   0          3s     10.42.1.6   master   ...
# rs-xxxx  1/1     Running   0          3s     10.42.1.7   master   ...
# rs-xxxx  1/1     Running   0          3s     10.42.1.8   master   ...
# rs-xxxx  1/1     Running   0          3s     10.42.1.9   master   ...
# rs-xxxx  1/1     Running   0          3s     10.42.1.10  master   ...
```

반대로 nodeSelector를 이용해서 명시적으로 worker 노드에서 실행되게 만들면 pending 상태가 된다.

```bash
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-worker
spec:
  containers:
  - image: nginx
    name: nginx
  nodeSelector:
    kubernetes.io/hostname: worker
EOF
# pod/pod-worker created

kubectl get pod -owide
# NAME         READY  STATUS    RESTARTS   AGE     IP       NODE    ... 
# ...
# pod-worker   0/1    Pending   0          70s     <none>   <none>  ...
```

## 2. uncordon

유지보수가 완료된 노드를 다시 스케줄링 가능한 상태로 만들기 위해선 uncordon을 사용하면 된다.

```bash
kubectl uncordon worker
# node/worker uncordoned

# taint가 사라졌습니다.
kubectl get node worker -oyaml | grep spec -A 10
# spec:
#   podCIDR: 10.42.1.0/24
#   podCIDRs:
#   - 10.42.1.0/24
#   providerID: k3s://worker
# status:
#   addresses:
#   - address: 172.31.16.173
#     type: InternalIP
#   - address: worker
#     type: Hostname

kubectl get node
# NAME     STATUS   ROLES    AGE   VERSION
# master   Ready    master   32d   v1.18.6+k3s1
# worker   Ready    worker   32d   v1.18.6+k3s1

kubectl get pod -owide
# NAME        READY   STATUS    RESTARTS   AGE   IP       NODE     ...
# ...
# pod-worker  1/1     Running   0          70s   <none>   worker   ...

kubectl delete pod pod-worker
# pod/pod-worker deleted
```

uncordon을 시키면 pending 상태인 Pod가 running 상태로 변경된다.

# drain

cordon은 새로운 Pod의 유입은 불가능하지만, 노드에서 실행되고 있던 기존 Pod에는 영향을 주지 않는다. 기존에 실행되고 있던 Pod도 중지시키고 싶다면 drain을 사용하면 된다.

```bash
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
EOF
# deployment.apps/pod-drain created

# nginx Pod가 워커 노드에 생성된 것을 확인할 수 있습니다.
kubectl get pod -o wide
# NAME               READY  STATUS    RESTARTS  AGE  IP           NODE
# nginx-7ff78b8-xxx  1/1    Running   0         42s  10.42.0.25   master
# nginx-7ff78b8-xxx  1/1    Running   0         42s  10.42.1.2    worker
# nginx-7ff78b8-xxx  1/1    Running   0         42s  10.42.4.62   worker
```

worker 노드에 3개의 Pod를 생성하고 drain을 해보자.

```bash
# 모든 노드에 존재하는 DaemonSet은 무시합니다.
kubectl drain worker  --ignore-daemonsets
# node/worker cordoned
# evicting pod "nginx-xxx"
# evicting pod "nginx-xxx"
# ...

# nginx Pod가 어떻게 동작하는지 확인합니다.
kubectl get pod -owide
# NAME              READY   STATUS    RESTARTS  AGE  IP          NODE
# nginx-7ff7b-xxx   1/1     Running   0         2m   10.42.0.25  master
# nginx-7ff7b-xxx   1/1     Pending   0         2m   <none>      <none>
 
kubectl get node worker -oyaml | grep spec -A 10
# spec:
#   podCIDR: 10.42.1.0/24
#   podCIDRs:
#   - 10.42.1.0/24
#   providerID: k3s://worker
#   taints:
#   - effect: NoSchedule
#     key: node.kubernetes.io/unschedulable
#     timeAdded: "2020-04-04T15:37:25Z"
#   unschedulable: true
# status:

kubectl get node
# NAME     STATUS                    ROLES    AGE   VERSION
# master   Ready                     master   32d   v1.18.6+k3s1
# worker   Ready,SchedulingDisabled  worker   32d   v1.18.6+k3s1
```

cordon에서 그랬던 것처럼 노드의 상태가 유지보수로 변하고, 여기에 더해 기존에 실행되고 있던 Pod이 pending 되는 것을 확인할 수 있다. drain 역시 uncordon으로 되돌리면 된다.

```bash
kubectl uncordon worker
# node/worker uncordoned
```

## Pod 개수 유지

drain을 사용하면 Pod가 갑자기 종료된다. 트래픽을 많이 받는 서비스의 경우, 순간적으로 모든 요청이 한쪽 Pod에게 집중되어 응답 지연이 발생할 수 있게 된다. PodDisruptionBudget(pdb)을 사용하면 이러한 문제를 해결할 수 있다.

pdb는 운영 중인 Pod의 개수를 항상 일정 수준으로 유지하도록 Pod의 evict를 막아주는 역할을 한다. 유지보수와 같은 목적으로 Pod을 중단하는 것은 장애로 인해 Pod이 종료되는 것이 아니기 때문에 사전에 이를 알 수 있다. 따라서 pdb는 노드가 유지보수 작업으로 인해 의도적으로 중단된 상황에서는 Pod의 개수를 일정 수준 이하로 내려가지 않도록 막아주게 된다.

```bash
kubectl scale deploy nginx --replicas 10
# deployment.apps/mydeploy scaled
```

테스트에 사용한 nginx의 레플리카를 10으로 변경하고, pdb를 통해 최소 9개의 Pod가 실행될 수 있도록 만들어보자.

```yaml
# nginx-pdb.yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
spec:
  minAvailable: 9
  selector:
    matchLabels:
      app: nginx
```
```bash
# pdb를 생성합니다.
kubectl apply -f nginx-pdb.yaml
# poddisruptionbudget/nginx-pdb created

# worker을 drain합니다.
kubectl drain worker --ignore-daemonsets
# node/worker cordoned
# evicting pod "nginx-xxx"
# evicting pod "nginx-xxx"
# error when evicting pod "mynginx-xxx" 
# (will retry after 5s): Cannot evict pod as it would violate the 
#   pod's disruption budget.
# pod/mynginx-xxx evicted
# evicting pod "mynginx-xxx"
# error when evicting pod "mynginx-xxx" 
# (will retry after 5s): Cannot evict pod as it would violate the 
#   pod's disruption budget.
# evicting pod "mynginx-xxx"
# pod/mynginx-xxx evicted
# node/worker evicted
```

pdb를 설정했기 때문에 총 10개의 Pod 중에서 9개가 유지되어야 해서, Pod이 1개씩 evict 되는 것을 확인할 수 있다. 중요한 것은 nginx는 9개가 실행되어야 하기 때문에 해당 노드에서 evcit 된 Pod는 다른 노드에서 생성이 되고 나서야 다음 Pod이 evict 된다는 것이다.

이를 통해 pdb가 적용된 네임스페이스에서 nginx Pod는 차례대로 줄어들고, 줄어든 만큼의 nginx Pod는 다른 노드에서 실행되어 서비스에 지장이 없도록 만들어 줄 것이다.

#### clean up

```bash
kubectl delete pdb nginx-pdb
kubectl delete deploy nginx
kubectl delete rs rs
kubectl uncordon worker
```