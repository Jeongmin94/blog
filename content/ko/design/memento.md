---
title: "메멘토 패턴"
date: 2022-11-22T18:46:49+09:00
draft: true
mermaid: true
mermaid: true
tags:
- memento
categories:
- design pattern
---
메멘토 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 메멘토 패턴

{{<mermaid>}}
classDiagram
    class CareTaker
    class Originator {
        - state
        + createMementor()
        + restore(Memento)
    }
    class Memento {
        - state
        + Memento(state)
    }
    Originator <-- CareTaker
    Memento <-- CareTaker
    Memento <-- Originator
{{</mermaid>}}

메멘토 패턴은 객체 내부의 정보를 외부에 저장해두었다가, 나중에 다시 외부의 정보를 기반으로 복원할 수 있도록 만드는 패턴이다.(ex. undo, restore)

일반적으로 객체를 외부에 저장시키고 getter/setter를 사용해서 해당 객체의 정보를 가져와 사용하면 되는 것이라 생각할 수 있지만, 이런 경우에는 객체의 캡슐화가 깨진 상태라고 볼 수 있다. 사용자가 객체 내부의 특정 데이터를 직접 알아야만 사용이 가능하기 때문이다. 사용자가 특정 객체의 데이터에 직접적으로 의존하게 되면 자연스레 개방 폐쇄 원칙을 지킬 수 없게 된다.

메멘토 패턴을 사용하게 되면 객체 내부의 정보를 Memento라는 타입으로 만들어 저장을 하게 된다. 그리고 이렇게 저장된 Memento 객체를 통해 원래 객체의 정보를 불러오고 싶다면 Originator에 있는 restore 메서드를 호출해주면 된다.

Memento라는 객체로 외부에 저장하고 싶은 데이터가 추상화 되어 있기 때문에 사용자는 객체의 세부 정보를 알 필요 없이 Memento 객체만 가지고 있으면 되고, 복원이 필요하다면 Memnto 객체를 restore 메서드에 넘겨주기만 하면 된다.

상태 저장과 복원에 대한 책임을 Memento 객체에서 담당하기 때문에 단일 책임 원칙을 지킬 수 있으며, 추상화 된 계층을 이용하여 저장하고 싶은 객체를 감싸기 때문에 개방 폐쇄 원칙을 지킬 수 있게 된다.

단점으로는 외부에 저장을 하는 Memento 객체의 크기가 늘어날 수 있고, 자주 생성한다면 메모리에 영향을 줄 수 있다.