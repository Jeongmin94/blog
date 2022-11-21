---
title: "책임 연쇄 패턴"
date: 2022-11-14T19:15:44+09:00
draft: true
mermaid: true
tags:
- chain of responsible pattern
categories:
- design pattern
---
책임 연쇄 패턴에 대해 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 책임 연쇄 패턴

{{<mermaid>}}
classDiagram
    class Client
    class Handler {
        + handleRequest(request)
    }
    ConcreteHandler {
        + handleRequest(request)
    }
    Handler <-- Handler
    Handler <|-- ConcreteHandler
{{</mermaid>}}

책임 연쇄 패턴은 요청을 보내는 쪽과 요청을 처리하는 쪽을 분리하는 패턴이다. 요청을 보내는 클라이언트에서는 `Handler` 인터페이스를 사용해서 특정한 작업을 요청하게 되며, `Handler`의 구현체가 해당 요청을 처리하게 된다.

여기서 중요한 점은 `Handler`에 등록되어 있는 구현체들은 여러개가 존재할 수 있으며, 필요에 따라 여러 구현체들을 모두 사용해서 특정 요청에 대한 작업을 수행할 수 있다는 부분이다. 이를 핸들러 체인이라 부른다. 클라이언트는 `Handler` 인터페이스로 추상화된 계층만을 바라보기 때문에 핸들러 체인의 조합이 어떻게 되든지 상관하지 않는다. 그저 자신의 작업을 처리해주는 `Handler`만 필요할 뿐이다.

책임 연쇄 패턴을 사용하면 클라이언트 코드 변경 없이 새로운 `ConcreteHandler`를 추가할 수 있어 개방 폐쇄 원칙을 지킬 수 있으며, 각 구현체들은 본인의 역할만을 담당하고 있기 때문에 단일 책임 원칙을 지킬 수도 있다.

핸들러 체인을 사용하기 때문에 특정 요청에 대한 작업을 처리하는 핸들러의 순서를 결정할 수 있으며, 특정 요청에 대해서는 핸들러의 작업을 생략할 수도 있게 된다.

하지만 핸들러 내부에 핸들러가 재귀적으로 존재하기 때문에 구조가 복잡하고, 어떤 부분에서 해당 작업이 실행됐는지 파악하기 어렵다는 단점을 가지고 있다.