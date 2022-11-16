---
title: "커맨드 패턴"
date: 2022-11-15T18:50:25+09:00
draft: true
mermaid: true
tags:
- command pattern
categories:
- design pattern
---
커맨드 패턴에 대해 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 커맨드 패턴

{{<mermaid>}}
classDiagram
    class Invoker
    class Receiver {
        + opertaion()
    }
    class Command {
        + execute()
    }
    class ConcreteCommand {
        + execute()
    }
    Command <-- Invoker
    Command <|-- ConcreteCommand
    Receiver <-- ConcreteCommand
{{</mermaid>}}

커맨드 패턴은 사용자의 요청을 캡슐화 하여 호출자(invoker)와 수신자(receiver)를 분리하는 패턴이다. 호출자는 `Command` 인터페이스로 추상화 된 계층을 통해서만 요청을 보낼 수 있게 되고, 내부의 구현 클래스에서 해당 요청을 처리할 수 있는 다양한 방법들을 지원하게 된다.

따라서 사용자(호출자) 입장에서는 `Command` 인터페이스만 알고 있으면 되기 때문에 내부의 구현체들이 어떤 방식으로 요청을 처리하는지 신경쓰지 않아도 된다.

이처럼 커맨드 패턴을 적용하게 되면 `Command` 계층을 통해서 요청 호출자의 요청을 수신자가 직접 처리하는 것이 아니라 호출자 -> 커맨드 계층 -> 수신자 순서로 요청이 이관되는 형식을 가지게 된다. 결과적으로 호출자는 앞서 설명했던 것처럼 호출하는 부분에서의 코드 변화 없이 새로운 작업을 요청할 수 있게 된다.

즉, 해당 패턴을 적용하게 되면 호출자가 직접 수신자를 통해 특정 작업을 수행하도록 요청하는 강한 결합력을 가진 형태를 중간에 추상화 계층인 커맨드 계층을 추가하여서 호출자와 수신자의 결합력을 낮추는 것이 목표가 된다.

이와 같은 특징 덕분에 호출자의 코드 변경 없이 새로운 요청을 처리하는 수신자를 커맨드 계층을 통해 추가할 수 있고, 마찬가지로 수신자의 코드가 변해도 해당 코드를 직접 호출하는 것이 아니라 커맨드 계층을 통해 호출하기 때문에 개방 폐쇄 원칙을 지킬 수 있게 된다. 또한, 각각의 커맨드가 본연의 역할만을 하기 때문에 단일 책임 원칙도 지키게 된다.

또한, 기능적으로도 커맨드 계층을 이용해서 단순히 특정 기능을 실행(execute)하라는 요청 외에도, 해당 요청을 취소(undo)하라는 요청도 추가해서 사용할 수 있다.