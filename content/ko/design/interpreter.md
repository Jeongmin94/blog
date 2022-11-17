---
title: "인터프리터 패턴"
date: 2022-11-17T19:11:29+09:00
draft: true
mermaid: true
tags:
- interpreter
categories:
- design pattern
---
인터프리터 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 인터프리터 패턴

{{<mermaid>}}
classDiagram
    class Client
    class Context
    class Expression {
        + interpret(Context)
    }
    TerminalExpression {
        + interpret(Context)
    }
    NonTerminalExpression {
        + interpret(Context)
    }
    Context <-- Client
    Expression <-- Client
    Expression <|.. TerminalExpression
    Expression <|.. NonTerminalExpression
    Expression <-- NonTerminalExpression
{{</mermaid>}}

인터프리터는 자주 발생하는 문제를 간단한 언어로 정의하고 재사용하는 패턴이다.

`Context`는 자주 발생하는 문제가 되며, `Expression`은 `Context`를 표현식으로 변경하고 구현 클래스를 가지고 문제를 해결하게 된다. 이때, 문제를 해결하는 방식은 `TerminalExpression`과 `NonTerminalExpression`으로 나누어 지는데 전자의 경우 해당 클래스에서 문제가 종료되고, 후자의 경우에는 재귀적으로 다른 `Expression` 구현체를 호출하게 된다.

## 실습

postfix 방식으로 덧셈, 뺄셈을 하는 계산기를 만든다고 가정한다. 이 계산기에서는 `123+-`라는 수식을 정말 자주 처리하기 때문에 이것을 인터프리터 패턴을 적용해서 해결하려고 한다. 계산기를 사용하는 입장에서는 다음과 같이 코드를 사용할 것이다.

```java
PostfixExpression expression = PostfixParser.parse("xyz+-");
Map<Character, Integer> context = Map.of('x', 1, 'y', 2, 'z', 3);
int result = expression.interpret(context);
```

- `PostfixParser` 클래스에서는 `123+-`가 추상회 된 `xyz+-`라는 패턴의 표현식이 들어오면 이것을 `Expression`에서 사용할 수 있도록 파싱해준다.
- x, y, z에 해당하는 값을 `context`에 넣어준다.
- `Expression` 객체에서 `context`를 인터프리터 처리하여 결과값을 반환한다.

인터프리터 패턴에서 각 표현식은 종단 표현식과 그렇지 않은 경우로 나눌 수 있다. 위의 예제에서 `xyz`와 같이 특정 수를 반환하는 표현식은 종단 표현식이 된다. `xyz` 각각에 해당하는 정수를 입력해주면 그것으로 인터프리터 작업이 종료되기 때문이다.

그러나 `+-`와 같은 연산자는 그 자체로 인터프리터를 할 수 없다. 피연산자가 필요하기 때문이다. 따라서 `+-`는 피연산자를 입력 받아 그것을 더해서 반환해주는 종단 표현식이 추가적으로 필요하게 된다.

### TerminalExpression 구현

표현식의 구현체를 구현하기 위해 인터페이스를 먼저 정의해보자.

```java
public interface PostfixExpression {
    int interpret(Map<Character, Integer> context);
}
```

먼저, `xyz`에 해당하는 문자를 입력해주면, 그에 맞는 정수를 리턴해주는 종단 표현식을 구현한다.

```java
public class VariableExpression implements PostfixExpression{

    private Character variable;

    public VariableExpression(Character variable) {
        this.variable = variable;
    }

    @Override
    public int interpret(Map<Character, Integer> context) {
        return context.get(variable);
    }
}
```

`VariableExpression`은 `xyz`에 포함되는 문자를 가지고 있으며, 인터프리터를 진행하게 되면 문자를 정수로 리턴해주게 된다. 

### NonTerminalExpression

이제 연산자를 처리할 표현식을 만들 차례이다. 연산자는 연산을 위해 피연산자가 두 개 필요하다. 따라서 다음과 같이 정의할 수 있다.

```java
public class PlusExpression implements PostfixExpression {
    private PostfixExpression left;
    private PostfixExpression right;

    public PlusExpression(PostfixExpression left, PostfixExpression right) {
        this.left = left;
        this.right = right;
    }

    @Override
    public int interpret(Map<Character, Integer> context) {
        return left.interpret(context) + right.interpret(context);
    }
}
```

연산자의 왼쪽에 위치한 숫자와, 연산자의 오른쪽에 위치한 숫자를 나타내는 left와 right 변수가 필요하고, 인터프리터를 실행하게 되면 왼쪽의 숫자와 오른쪽의 숫자를 더해서 반환해주면 된다. 덧셈 표현식이 아닌 뺄셈 표현식이라면 -를 사용해주면 된다.

결국 `context`라는 변수는 `123+-`로 대표되는 자주 등장하는 문제를 인터프리터 패턴에서 사용하기 위해 연산자, 피연산자로 분해되었고, 각각의 요소들을 `Expression`이라는 인터페이스를 만들어 연산자는 연산자에 필요한 인터프리터 작업을, 피연산자는 피연산자에 필요한 인터프리터 작업을 하게 되는 것을 알 수 있다.

### 파서

```java
public class PostfixParser {
    public static PostfixExpression parse(String expression) {
        Stack<PostfixExpression> stack = new Stack<>();

        for (char c : expression.toCharArray()) {
            stack.push(getExpression(c, stack));
        }

        return stack.pop();
    }

    public static PostfixExpression getExpression(char c, Stack<PostfixExpression> stack) {
        switch (c) {
            case '+':
                return new PlusExpression(stack.pop(), stack.pop());
            case '-':
                PostfixExpression right = stack.pop();
                PostfixExpression left = stack.pop();
                return new MinusExpression(left, right);
            default:
                return new VariableExpression(c);
        }
    }
}
```

파서에서 `xyz+-`와 같은 문자열을 우리가 필요로 하는 표현식으로 변경시켜 주게 된다. 우리가 원하는 표현식은 포스트픽스 방식의 계산을 위해 만들어진 `PostfixExpression`이기 때문에 실제로 포스트픽스 방식으로 계산을 하는 과정과 동일하게 피연산자용 `VariableExpression`과 연산자용 `PlusExpression`, `MinusExpression`을 만들어서 스택에 추가해주면 된다.

즉, `123+-`를 직접 스택을 활용해서 계산하는게 아니라, 이를 패턴화된 문제인 `xyz+-` 형식으로 변환시키고, 이것을 표현식에서 처리할 수 있게끔 `PostfixExpression`이라는 인터페이스의 구현체로 만들어준 것이다.

이렇게 파서를 통해 생성된 표현식은 내부적으로 인터프리터에 필요한 여러 표현식 구현체들을 가지고 있고, 종단 표현식이 아닌 경우에는 인터프리터를 종료시키기 위해 재귀적으로 내부의 또 다른 표현식의 인터프리터를 실행하게 된다. 위의 파서에서는 다음과 같은 구성을 가지게 된다.

```bash 
MinusExpression {
    # left, right
    - VariableExpression { x }
    - PlusExpression {
        # left right
        - VariableExpression { y }
        - VariableExpression { z }
        + interpret(context)
      }
    + interpret(context)
}
```