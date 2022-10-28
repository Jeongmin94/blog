---
title: "컴포지트 패턴"
date: 2022-10-28T22:07:22+09:00
draft: true
mermaid: true
tags:
- composite
categories:
- design pattern
---
컴포지트 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 컴포지트 패턴

{{<mermaid>}}
classDiagram
    class Client
    class Component {
        + operation()
    }
    class Leaf {
        + operation()
    }
    class Composite {
        - children: Component[]
        + operation()
    }
    Component <-- Client
    Component <|-- Leaf
    Component <-- Composite
    Leaf <|-- Composite
{{</mermaid>}}

컴포지트 패턴은 그룹 전체와 개별 객체를 동일하게 처리할 수 있게 만들어주는 디자인 패턴이다. 클라이언트 입장에서 전체나 부분이나 모두 동일한 컴포넌트로 인식을 하게 만드는 계층 구조 덕분에 그룹 전체에 대한 연산을 손쉽게 처리할 수 있다.

컴포지트 패턴을 사용하게 되면 트리 자료구조의 이점을 잘 살려 재귀 호출을 통해 간단하게 복합적인 작업을 실행할 수 있게 된다. 이 과정에서 클라이언트가 호출하는 대상을 Component라는 추상 계층으로 만들어 사용하기 때문에 새로운 타입의 컴포지트를 추가하기에 용이하다.(개방 폐쇄 원칙)

하지만 Component로 대표되는 추상 계층에서 정의한 공통 인터페이스를 만들기 위해 억지로 일반화 작업을 하는 경우도 발생하게 된다. 이렇게 될 경우 최상의 상황에서는 Component로 추상화를 시켜놓고, 다시 하위 타입을 체크해서 사용하는 경우가 발생할 수 있게 된다.

