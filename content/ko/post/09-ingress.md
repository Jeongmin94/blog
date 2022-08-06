---
title: "09 Ingress"
date: 2022-07-29T19:47:44+09:00
draft: true
tags:
- ingress
categories:
- k8s
---
어플리케이션 계층에서 외부 트래픽을 처리하는 Ingress 리소스에 대해 알아본다.
<!--more-->

# Ingress 리소스

많은 웹 서비스들은 어플리케이션 계층에서 네트워크 통신을 수행한다. 주로 사용하는 7계층(어플리케이션 계층)의 프로토콜은 HTTP, HTTPS가 있는데, 쿠버네티스에서는 이 7계층에서 클러스터로 들어오는 트래픽을 Ingress 리소스를 통해 관리한다.

Ingress 리소스의 가장 기본적인 역할은 외부 HTTP 호출에 대한 트래픽 처리다. 부하 분산, TLS 종료, 도메인 기반 라우팅 기능 등이 대표적인 기능이라 할 수 있다. Ingress 리소스는 클러스터 내부에 외부에서 접근할 수 있도록 URL을 부여하여, 일반 사용자들이 클러스터에 쉽게 접근할 수 있는 통로를 제공해준다.

이러한 기능은 Ingress Controller에서 제공하며, Ingress Controller는 Ingress에 정의된 트래픽 라우팅 규칙을 보고 라우팅을 진행한다.

## 1. Ingress Controller

Ingress 리소스는 하나의 정의일 뿐이다. Ingress 리소스 자체는 외부에서 들어오는 트래픽 처리에 대한 정보를 가지고 있을 뿐, Ingress에 작성된 규칙을 읽고 외부의 트래픽을 Service 리소스로 전달하는 주체는 Ingress Controller이다.

쿠버네티스에는 각 리소스에 대응하는 리소스 컨트롤러가 존재하는데, Ingress에 정의된 내용에 따라 특정 작업을 수행하는 주체가 바로 Ingress 리소스의 Ingress Controller가 되겠다.

Ingress Controller는 쿠버네티스 내장 컨트롤러와 다르게 명시적으로 컨트롤러를 설치해야 하며, 여러 종류의 Ingress Controller 구현체 중에서 자신의 용도와 목적에 맞게 선택해서 사용할 수 있다. 대표적인 Ingress Controller는 다음과 같다.

- NGINX Ingress Controller
- HAProxy
- AWS ALB Ingress Controller
- Ambassador
- Kong
- traefik

### NGINX Ingress Controller

예제에서는 NGINX Ingress Controller를 사용한다. 설치 방법은 다음과 같다.

```bash
# NGINX Ingress Controller를 위한 네임스페이스를 생성합니다.
kubectl create ns ctrl
# namespace/ctrl created

# nginx-ingress 설치
helm install ingress stable/nginx-ingress --version 1.40.3 -n ctrl
# NAME: ingress
# LAST DEPLOYED: Wed Mar 11 13:31:14 2020
# NAMESPACE: ctrl
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
#     ...
```

NGINX Ingress Controller와 관련된 Pod과 Service가 생성된 것을 확인해보자.

```bash
kubectl get pod -n ctrl
# NAME                            READY   STATUS      RESTARTS  AGE
# ingress-controller-7444984      1/1     Running     0         6s
# svclb-ingress-controller-dcph4  2/2     Running     0         6s
# ingress-default-backend-659bd6  1/1     Running     0         6s
 
kubectl get svc -n ctrl
# NAME                     TYPE          ...  EXTERNAL-IP    PORT(S)  
# ingress-default-backend  ClusterIP     ...  <none>         80/TCP
# ingress-controller       LoadBalancer  ...  10.0.1.1       80:32249/TCP,443:30734/TCP
```

Service 리소스를 보면, 80번 포트와 443 포트가 LoadBalancer 타입을 가진 ingress-nginx-controller 리소스에 할당된 것을 볼 수 있다. 앞으로 Ingress로 들어오는 모든 트래픽은 ingress-nginx-controller에서 처리하게 된다.

## 2. Ingress 기본 사용법

### 도메인 주소 테스트

Ingress는 7계층 통신이기 때문에 도메인 주소를 가지고 있어야 제대로 된 Ingress 테스트를 할 수 있다. `https://sslip.io/`라는 서비스를 이용하면 따로 도메인을 신청하지 않아도 도메인 주소를 얻을 수 있다.

```bash
IP == IP.sslip.io

nslookup 10.0.1.1.sslip.io
# Address: 10.0.1.1

nslookup subdomain.10.0.1.1.sslip.io
# Address: 10.0.1.1
```

### Ingress Controller IP 확인 방법

```
INGRESS_IP=$(kubectl get svc -nctrl ingress-nginx-controller -ojsonpath="{.status.loadBalancer.ingress[0].ip}")
echo $INGRESS_IP
# 10.0.1.1
```

## 3. Ingress 생성

Ingress와 연결할 nginx 서비스부터 생성한다.

```bash
kubectl run mynginx --image nginx --expose --port 80
# pod/mynginx created
# pod/service created

# comma로 여러 리소스를 한번에 조회할 수 있습니다.
kubectl get pod,svc mynginx
# NAME          READY   STATUS    RESTARTS   AGE
# pod/mynginx   1/1     Running   0          8m38s

# NAME             TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
# service/mynginx  ClusterIP  10.43.203.151  <none>        80/TCP    8m38s
```

Ingress 리소스를 정의한다.

```yaml
# mynginx-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: mynginx
spec:
  rules:
  - host: 10.0.1.1.sslip.io
    http:
      paths:
      - path: /
        backend:
          serviceName: mynginx
          servicePort: 80
```

- annotations : 어노테이션은 메타정보를 저장하기 위한 property이다. label과 비슷하지만 어노테이션으로는 리소스를 필터하지는 못하고 단지 메타 데이터를 저장하는 용도로 사용한다. Ingress에서는 Ingress Controller에게 메타 정보를 전달할 목적으로 사용한다.
- rules : 외부 트래픽을 어떻게 처리할지 정의한다.
  - host : 특정 도메인으로 들어오는 트래픽에 대해 라우팅을 정의한다. 생략하면 모든 호스트 트래픽을 처리한다.
  - http.paths[0].path : Ingress path를 정의한다.
  - http.paths[0].backend: Ingress의 트래픽을 받을 Serrvice와 포트를 정의한다.

```bash
kubectl apply -f mynginx-ingress.yaml
# ingress.extensions/mynginx created

kubectl get ingress
# NAME      CLASS    HOSTS              ADDRESS    PORTS     AGE
# mynginx   <none>   10.0.1.1.sslip.io  10.0.1.1   80        10m

# mynginx 서비스로 연결
curl 10.0.1.1.sslip.io
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...
```