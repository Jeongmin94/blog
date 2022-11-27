---
title: "상태 패턴"
date: 2022-11-27T16:36:39+09:00
draft: true
mermaid: true
tags:
- state
categories:
- design pattern
---
상태 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 상태 패턴

{{<mermaid>}}
classDiagram
    class Client
    class Context {
        - state: Sate
        + Context(State)
        + changeState(State)
        + operation()
    }
    class State {
        + operation()
    }
    class ConcreteState {
        + setContext(Context)
        + operation()
    }
    Context <-- Client
    State <-- Context
    State <|.. ConcreteState
    Context <-- ConcreteState
{{</mermaid>}}

상태 패턴은 객체의 특정한 상태에 대한 패턴이다. 객체 내부의 상태 변경에 따라 객체의 행동을 다르게 만들 수 있다.

애플리케이션 내의 특정 객체가 상태에 따라 로직을 분기 처리하게 되면, 상태가 점점 많아짐에 따라 코드가 점점 복잡해지게 된다. 이러한 경우에 상태 패턴을 적용하게 되면 특정 상태에 대한 행동을 분리할 수 있게 되고, 분리를 통해 새로운 행동 추가가 유연하게 가능해진다.(개방 폐쇄 원칙)

상태에 따른 동작을 개별 클래스로 옮기기 때문에 단일 책임 원칙을 지킬 수 있게 된다. 또한, 하나의 메서드에 존재하는 분기 처리들을 나눌 수 있기 때문에 코드의 복잡도를 줄일 수 있기도 하다.