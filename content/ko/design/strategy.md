---
title: "전략 패턴"
date: 2022-11-28T09:24:41+09:00
draft: true
mermaid: true
tags:
- strategy
categories:
- design pattern
---
전략 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 전략 패턴

{{<mermaid>}}
classDiagram
    class Client
    class Context {
        - strategy: Strategy
        + operation()
    }
    class Strategy {
        + execute()
    }
    class ConcreteStrategy {
        + setContext(Context)
        + operation()
    }
    Context <-- Client
    ConcreteStrategy <-- Client
    Strategy <-- Context
    Strategy <|.. ConcreteStrategy
{{</mermaid>}}

전략 패턴은 특정한 작업을 수행하는 방법이 여러가지인 경우에, 각 방법을 캡슐화 시키고 공통된 부분을 인터페이스로 추상화시켜 사용자는 추상화된 계층만 사용할 수 있도록 만든 패턴이다.

사용자는 직접 ConcreteStrategy 중 하나를 선택해서 Context에 건내주고, Context에서 operation 메서드를 실행하여 각각의 전략에 맞는 작업을 할 수 있게 된다.

Strategy라는 추상화된 계층을 사용하기 때문에 필요에 따라 새로운 전략을 만들어서 사용자에게 전달할 수만 있다면, 다른 코드에 영향을 주지 않고 새로운 전략을 유연하게 추가할 수 있게 된다.(개방 폐쇄 원칙) 동시에 전략을 구현한 클래스에서는 자신이 담당한 기능만을 구현하기 때문에 단일 책임 원칙 역시 지키게 된다.
