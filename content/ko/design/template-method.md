---
title: "템플릿 메서드 패턴"
date: 2022-12-01T17:05:46+09:00
draft: true
mermaid: true
tags:
- template-method
categories:
- design pattern
---
템플릿 메서드 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 템플릿 메서드 패턴

{{<mermaid>}}
classDiagram
    class AbstractClass {
        + templateMethod()
        + step1()
        + step2()
    }
    class ConcreteClass {
        + step1()
        + step2()
    }
    AbstarctClass <|-- ConcreteClass
{{</mermaid>}}

템플릿 메서드 패턴은 특정 문제를 해결하는 알고리즘의 구조를 템플릿으로 정의하고, 문제를 해결하기 위한 각 과정을 서브 클래스를 통해 제공해주는 패턴이다. 템플릿 메서드 패턴은 상속을 사용한다.

서브 클래스에서는 구체적인 문제 해결 방법을 제공해주고, 슈퍼 클래스에서는 각 과정을 추상화 시켜 템플릿 메서드로 제공한다.

## 템플릿 콜백 패턴

템플릿 콜백 패턴은 템플릿 메서드 패턴과 유사하지만, 상속 대신 위임을 사용한다는 차이를 가지고 있다. 단, 콜백의 구현체에서는 하나의 메서드만 가지고 있어야 한다. 따라서 콜백을 람다 표현식이나 익명 내부 클래스를 사용해서 손쉽게 구현할 수 있게 된다.

{{<mermaid>}}
classDiagram
    class Callback {
        + operation()
    }
    class AbstractClass {
        + templateMethod(Callback)
        + step1()
        + step2()
    }
    class ConcreteCallback {
        + operation()
    }
    Callback <|.. ConcreteCallback
    Callback <-- AbstractClass
{{</mermaid>}}

템플릿 메서드 패턴을 사용하면 템플릿을 통해 재사용되는 중복 코드를 줄일 수 있고, 상속을 통해 구체적인 알고리즘만 변경할 수 있게 된다.

그러나 상속을 사용하기 때문에 리스코프 치환 원칙을 위배할 수 있다. 리스코프 치환 원칙은 상속을 받은 클래스에서 재정의한 메서드가 부모 클래스에서 정의한 메서드의 의도를 해치는 경우를 의미하는데, 템플릿 메서드 패턴에서는 상속을 사용하기 때문에 자식 클래스에서 부모 클래스의 템플릿 메서드와 각 알고리즘들을 재정의하여 다른 의도를 가지게 만들 수 있기 때문이다.

또한, 템플릿이 복잡한 경우에는 유지보수에 어려움을 가질 수 있다.