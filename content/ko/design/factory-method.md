---
title: "팩토리 메서드 패턴"
date: 2022-09-28T20:33:21+09:00
draft: true
mermaid: true
tags:
- factory method
categories:
- design pattern
---
팩토리 메서드 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 팩토리 메서드 패턴

{{<mermaid>}}
classDiagram
    class Creator {
        + templateMethod()
        + createProduct(): Product
    }
    class ConcreteCreator {
        + createProduct(): Product
    }
    class Product
    class ConcreteProduct
    Creator <|-- ConcreteCreator
    Product <|-- ConcreteProduct
    Creator o.. Product: use
{{</mermaid>}}

팩토리 메서드 패턴은 구체적으로 어떤 인스턴스를 만들지는 서브 클래스에서 정하게 만드는 방법을 의미한다. 즉, 인스턴스를 생성하는 코드를 단순히 생성자를 이용하는 것이 아니라 별도의 클래스나 메서드로 분리해서 사용한다는 것이다.

인스턴스의 생성 부분을 별도의 클래스, 메서드로 분리를 하게 되면 새로운 타입의 인스턴스를 추가하기 위해 새로운 코드를 작성하면서 기존에 있던 인스턴스 생성 코드를 수정하지 않아도 되기 때문에 개방 폐쇄 원칙을 지킬 수 있게 된다.

개방 폐쇄 원칙은 확장에는 열려 있고, 변경에는 닫혀있게 클래스를 설계하는 객체 지향 원칙 중 하나다. 확장이라는 것은 특정 클래스에 새로운 기능을 추가하는 것을 의미하는데, 일반적으로 대부분의 코드는 확장에는 열려 있다.(개발자가 코드를 추가하면 그게 확장이라고 볼 수 있기 때문이다.) 그러나 새로운 기능을 추가할 때, 다른 클래스에 영향을 주지 않는게 중요한 부분이다.

다른 코드에 영향을 주게 되면 새로운 기능이 추가될 때마다 객체 간의 결합도가 높아지게 되어 결과적으로는 유지보수하기 힘든 코드가 남게 된다.

팩토리 메서드 패턴에서는 인스턴스의 생성 부분을 실제 구현 클래스에서 담당하고 있기 때문에 새로운 타입이 추가되어도 각 구현 클래스의 인스턴스 생성 부분만 작성해주면 손쉽게 인스턴스 생성 기능을 추가할 수 있게 된다.

## 심플 팩토리 메서드 패턴

일반적인 팩토리 메서드 패턴은 인스턴스의 생성을 구현체로 넘기게 된다. 이런 경우에는 패키지 구조가 점차 복잡해진다는 단점이 있다. 패키지 구조가 복잡해지는게 싫다면, 심플 팩토리 메서드 패턴을 사용해볼 수 있다.

```java
public class SimpleFactory {
    public Object createProduct(String name) {
        if(name.equals("A")) {
            return new A();
        } else if(name.equals("B")) {
            return new B();
        }

        throw new IllegalArgumentException();
    }
}
```

심플 팩토리 메서드는 인스턴스 생성의 역할을 구현체로 넘기는 것이 아니라 자신이 직접 생성하게 된다. 이때 인스턴스 타입은 인스턴스 생성 메서드의 인수로 들어온 값에 따라 변하게 만드는 것이다.

이렇게 되면 단순한 패키지 구조를 사용하여 팩토리 메서드를 구현할 수 있게 되지만, 인스턴스 생성에 대한 요구사항이 끊임없이 변하는 경우에는 `createProduct`와 같은 메서드가 점차 비대해진다는 단점을 가진다. 따라서 인스턴스의 타입 확장이 제한적인 경우에는 심플 팩토리 메서드 사용을 고려해보는 것도 좋은 선택이 될 것이다.