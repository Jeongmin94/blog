---
title: "비지터 패턴"
date: 2022-12-02T11:37:29+09:00
draft: true
mermaid: true
tags:
- visitor
categories:
- design pattern
---
비지터 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 비지터 패턴

{{<mermaid>}}
classDiagram
    class Element {
        + accept(Visitor)
    }
    class ElementA {
        + accept(Visitor)
    }
    class ElementB {
        + accept(Visitor)
    }
    class Visitor {
        + visit(ElementA)
        + visit(ElementB)
    }
    class ConcreteVisitor {
        + visit(ElementA)
        + visit(ElementB)
    }
    Visitor <-- Element
    Visitor <|.. ConcreteVisitor
    Element <|.. ElementA
    Element <|.. ElementB
    ElementA <-- ConcreteVisitor
    ElementB <-- ConcreteVisitor
{{</mermaid>}}

비지터 패턴은 기존 코드를 건드리지 않고 새로운 기능을 추가할 수 있는 패턴이다. 구체적인 클래스를 찾아가는 과정이 런타임 중에 두 번 발생하는 더블 디스패치가 사용된다.

- Element에서 비지터를 허용하기 위해 Visitor의 구현 클래스를 찾음
- Visitor에서 어떤 Element에 대해 visit을 하기 위해 Element의 구현 클래스를 찾음

그러나 비지터 패턴의 구조는 다른 디자인 패턴과 비교해도 복잡한 편이다.

Element에 새로운 타입의 Visitor를 추가하는 작업은 Element가 인터페이스인 Visitor를 개방 폐쇄 원칙을 지킬 수 있으나, Visitor 입장에서는 Element의 타입에 따른 메서드 오버로딩을 진행하기 때문에(메서드 오버로딩은 컴파일 타임에 진행됨) 새로운 Element가 추가되거나 기존 Element가 제거되는 일이 발생하면 코드를 수정해야만 한다.