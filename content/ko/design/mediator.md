---
title: "메디에이터 패턴"
date: 2022-11-21T20:02:45+09:00
draft: true
mermaid: true
tags:
- mediator
categories:
- design pattern
---
메디에이터 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 메디에이터 패턴

{{<mermaid>}}
classDiagram
    class Mediator {
        + mediate()
    }
    class ConcreteMediator {
        + mediate()
    }
    class Colleague
    class ColleagueA
    class ColleagueB
    Mediator <-- Colleague
    Mediator <|.. ConcreteMediator
    Colleague <|-- ColleagueA
    Colleague <|-- ColleagueB
    ColleagueA <-- ConcreteMediator
    ColleagueB <-- ConcreteMediator
{{</mermaid>}}

메디에이터(중재자) 패턴은 객체 간의 의사소통을 위해 중재자를 두는 패턴이다. 중재자를 통해 메시지를 주고 받기 때문에 중재자의 반대편에 어떤 종류의 객체가 있는지 신경 쓸 필요가 없으며, 전달하고자 하는 메시지만 전달하면 된다.

메디에이터를 통해 여러 객체가 소통하는 방법을 캡슐화 하기 때문에 각 객체의 코드를 변경하지 않고, 새로운 메디에이터를 만들게 되면 새로운 소통 방법을 만들어 사용할 수 있게 된다. 이를 통해 개방 폐쇄 원칙을 지킬 수 있게 된다.

또한, 각 객체는 자신이 맡고 있는 본연의 역할만 수행하고 다른 객체와의 소통에 대한 책임은 메디에이터에 위임하기 때문에 단일 책임 원칙도 지킬 수 있게 된다.

하지만 메디에이터에 모든 의존성을 몰아주는 것이 메디에이터 패턴이기 때문에, 코드의 규모가 커질수록 메디에이터 클래스의 복잡도와 결합도가 증가하게 된다.