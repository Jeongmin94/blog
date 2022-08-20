---
title: "08 Helm"
date: 2022-07-24T09:05:48+09:00
draft: false
tags:
- helm
categories:
- k8s
---
helm 패키지 매니저에 대해 알아본다.
<!--more-->


# helm 패키지 매니저
helm은 쿠버네티스의 패키지 매니저로 `apt`, `yum`, `pip`와 비슷한 플랫폼의 패키지를 관리하는 역할을 한다.

helm 패키지는 YAML 형식으로 구성되어 있으며, 이를 chart라고 부른다.

helm chart의 구조는 크게 values.yaml, templates/ 디렉토리로 구성된다.

- values.yaml : 사용자가 원하는 값들을 설정하는 파일
- templates/ : 설치할 리소스 파일들이 존재하는 디렉토리. 해당 디렉토리 안에 Deployment, Service 등과 같은 쿠버네티스의 리소스가 YAML 형식으로 들어 있다. 각 YAML 파일의 설정값은 비어 있고, values.yaml의 설정값으로 채워진다.

쿠버네티스에서는 helm을 이용하여 프로세스(Pod)와 네트워크(Service), 저장소 등 어플리케이션에 필요한 모든 자원을 helm 패키지 매니저를 통해 외부에서 가져올 수 있다.

## 1. helm 설치

helm을 설치하는 방법은 간단하다.
```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash -s -- --version v3.2.2
```
## 2. chart 생성

chart는 리소스들을 편리하게 배포하거나 공유할 수 있게 패키징한 설치 파일들의 묶음이다. `mychart`라는 이름을 가진 테스트용 chart를 만들어 본다.

```bash
helm create mychart
# Creating mychart

ls mychart
# Chart.yaml  charts  templates  values.yaml
```

- Chart.yaml : chart 이름, 버전 정보 등 chart의 메타데이터를 담고 있다.
- charts : chart 속에 또 다른 여러 chart를 넣을 수 있다. 기본적으로는 비어 있다.
- templates/ : chart의 뼈대가 되는 쿠버네티스 리소스가 들어있는 폴더이다.
- values.yaml : 사용자 정의 설정값을 가진 YAML 파일이다.

```bash
ls mychart/templates
# NOTES.txt
# _helpers.tpl
# deployment.yaml
# ingress.yaml
# service.yaml
# serviceaccount.yaml
# tests/
```

templates 디렉토리에 여러 쿠버네티스 리소스의 YAML 정의서가 있는 것을 확인할 수 있다. `templates/service.yaml` 파일을 열어 확인해보면, values.yaml의 설정값을 사용하기 위해 플레이스홀더(placeholder)가 지정되어 있는 것을 볼 수 있다.

```yaml
# mychart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}         # 서비스 타입 지정
  ports:
    - port: {{ .Values.service.port }}     # 서비스 포트 지정
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "mychart.selectorLabels" . | nindent 4 }}
```

`Values.service.type`, `Values.service.port`가 플레이스홀더로 등록되어 있다. values.yaml에서는 실제로 이 값을 채울 수 있는 필드들이 있다.

```yaml
# values.yaml
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

...
# 약 40줄
service:
  type: LoadBalancer  # 기존 ClusterIP
  port: 8888          # 기존 80

...
```

values.yaml 파일을 확인해보면 각 리소스에서 사용할 설정값들을 입력할 수 있는 필드가 존재하고, Service 리소스는 조금 전에 살펴 본 플레이스홀더에 들어갈 type과 port가 디폴트값으로 설정되어 있는 것을 확인할 수 있다. 그래서 디폴트값을 각각 `LoadBalancer`와 `8888`로 변경하고 helm chart를 설치해서 변경된 값을 확인해볼 것이다.

## 3. chart 설치

```bash
helm install <CHART_NAME> <CHART_PATH>

helm install foo ./mychart
# NAME: foo
# LAST DEPLOYED: Tue Mar 10 14:26:02 2020
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# NOTES:
#    ....
```

`foo`라는 이름을 가진 chart를 생성했다. 도커를 사용하면 프로세스 실행에 필요한 개별 환경을 모두 컨테이너 내부에서 해결할 수 있었던 만큼, chart 생성하는 과정도 패키지에 필요한 별도의 라이브러리 없이 실행에 필요한 프로세스만 생성된다. 따라서 `kubectl` 명령어를 사용해서 chart에서 정의된 쿠버네티스의 리소스들이 실행되었는지 확인해보자.

```bash
# service 리소스를 조회합니다.
kubectl get svc
# NAME         TYPE          CLUSTER-IP      EXTERNAL-IP    PORT(S)   
# kubernetes   ClusterIP     10.43.0.1       <none>         443/TCP   
# foo-mychart  LoadBalancer  10.43.142.107   10.0.1.1       8888:32597/TCP 
```

Service 리소스를 확인해보면, `mychart`라는 Service 리소스의 타입과 포트 번호가 values.yaml에서 변경한 값이 적용되어 있다. 플레이스홀더에 정상적으로 설정값이 적용된 것이다.

## 4. helm 리스트 조회

helm을 통해서 여러 chart를 설치할 수 있다. `-n` 옵션을 사용하면 다른 `kubectl` 명령어와 동일하게 네임스페이스별로 분류를 할 수 있다.

```bash
# 설치된 chart 리스트 확인하기
helm list
# NAME    NAMESPACE  REVISION  UPDATED   STATUS    CHART          APP VER
# foo     default    1         2020-3-1  deployed  mychart-0.1.0  1.16.0

# 다른 네임스페이스에는 설치된 chart가 없습니다.
helm list -n kube-system
# NAME   NAMESPACE   REVISION    UPDATED STATUS  CHART   APP   VERSION
```

## 5. chart 랜더링

방금 전에 실행한 `helm install` 명령어는 chart를 설치하고 실행까지 되는 명령어다. chart가 설치, 실행되는 것이 아니라 values.yaml 파일과 templates 디렉토리 안에 있는 템플릿 YAML 정의서가 합쳐진 YAML 정의서가 보고 싶다면 `template` 명령어를 사용한면 된다. helm에서는 이러한 작업을 렌더링한다고 표현을 한다. `--dry-run`과 비슷하다고 생각하면 된다.

```bash
helm template foo ./mychart > foo-output.yaml

cat foo-output.yaml
# 전체 YAML 정의서 출력
```

이렇게 만들어진 `foo-output.yaml`에는 values.yaml에서 설정한 값들이 각각의 템플릿에 적용되어 있는 것을 볼 수 있다. 이를 통해 `helm install` 명령어는 다음과 같다고 할 수 있겠다.

```bash
helm install <NAME> <CHART_PATH> == helm template <NAME> <CHART_PATH> \
    output.yaml && kubectl apply -f output.yaml
```

## 6. chart 업그레이드

이미 설치한 chart의 values.yaml 값을 수정하고 업그레이드를 할 수 있다. Service 리소스의 타입을 NodePort로 수정하고 다시 배포해보자.

```bash
# values.yaml
...

service:
  type: NodePort    # 기존 LoadBalancer
  port: 8888        
...
```

```bash
# 업그레이드
helm upgrade foo ./mychart
# Release "foo" has been upgraded. Happy Helming!
# NAME: foo
# LAST DEPLOYED: Mon Jul  6 19:26:35 2020
# NAMESPACE: default
# STATUS: deployed
# REVISION: 2
# ...

kubectl get svc
# NAME        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          
# kubernetes  ClusterIP   10.43.0.1      <none>        443/TCP   
# foo         NodePort    10.43.155.85   <none>        8888:32160/TCP 

helm list
# NAME     NAMESPACE  REVISION   UPDATED    STATUS      CHART      
# foo      default    2          2020-3-2   deployed    mychart-0.1.0 
```

업그레이드된 `foo`를 확인해보면 REVISION 숫자가 2로 변경되었다. 업그레이드 역시 쿠버네티스의 리소스를 사용해서 진행하기 때문에 REVISION 역시 변경된 것이다.

## 7. chart 배포상태 확인

배포된 chart의 상태를 확인하기 위해 다음과 같은 명령을 사용한다.

```bash
helm status foo
# Release "foo" has been upgraded. Happy Helming!
# NAME: foo
# LAST DEPLOYED: Mon Jul  6 19:26:35 2020
# NAMESPACE: default
# STATUS: deployed
# REVISION: 2
# ...
```

## 8. chart 삭제

생성하고 나서 필요 없어진 chart는 `delete` 명령을 사용해서 삭제할 수 있다.

```bash
helm delete foo
# release "foo" uninstalled

helm list
# NAME   NAMESPACE   REVISION    UPDATED STATUS  CHART   APP   VERSION
```
