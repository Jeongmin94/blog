---
title: "@Autowired"
date: 2022-10-24T21:36:15+09:00
draft: true
mermaid: true
tags:
- dependency injection
categories:
- spring
---
스프링의 @Autowired 어노테이션을 알아본다.
<!--more-->

> https://kellis.tistory.com/58?category=849601
> https://kellis.tistory.com/70

# @Autowired

스프링의 핵심 기능이라 할 수 있는 의존성 주입. @Autowired 어노테이션을 생성자, 필드, setter에 사용하면 손쉽게 필요한 객체를 스프링의 IoC 컨테이너로부터 주입받아 사용할 수 있게 된다.

그런데 @Autowired를 사용하는 경우 필드 주입을 주의하라는 경고 문구를 비롯해, 필드 주입에 대한 여러 단점들을 들을 수 있었다. 그러나 궁금한 것은 생성자나 setter를 통한 의존성 주입은 클래스 외부에서도 클래스에 정의된 명세(생성자 인수나 setter의 타입과 인수 등)에 따라 가능할 것이라 생각했는데, 필드 주입은 도대체 어떻게 가능한지가 궁금했다. 그래서 찾아봤다.

### 스프링 의존성 주입 절차

스프링 프레임워크에서 빈(Bean)을 생성하고 관리하는 일은 IoC 컨테이너가 담당하고 있다. 자바 코드에서는 `ApplicationContext`의 구현체를 이용해서 IoC 컨테이너를 사용할 수 있게 된다.

`ApplicationContext`는 `Final Bean Definition`을 생성한다. 이는 스프링 빈의 메타 데이터라고 보면 되는데, 빈 생성에 필요한 각종 정보들을 포함하고 있다.

IoC 컨테이너가 빈의 라이프 사이클을 관리하는데, 이를 위해 유용하게 사용하는 것이 바로 `Bean Definition`이라고 보면 된다. 이 메타 데이터에는 빈의 생성 방법, 라이프 사이클, 종속성 등에 대한 정보가 들어있기 때문이다.(xml 파일에서 bean 태그로 작성하는 것들 대부분이라고 보면 된다.)

그래서 스프링이 실행될 때, `ApplicationContext`에서 빈으로 등록되어야 할 클래스들 - 각종 어노테이션(@Bean, @Repository, @Service 등), xml 설정 파일에 정의된 내용 - 을 빈으로 생성하고, 그 다음에 @Autowired 어노테이션을 찾아 해당 위치에 의존성 주입을 해주는 것이다.

정리하면 xml 파일이나, 각종 어노테이션을 통해 빈으로 등록하고 싶은 클래스들을 정해놓으면, `ApplicationContext`에서 `Bean Definition`이라는 것을 만들고, 이를 기반으로 빈을 생성하게 된다. 그리고 @Autowired 어노테이션이 사용된 곳이 있다면, 의존성 주입을 실행해준다.

여기서 알 수 있는 부분은 의존성 주입이 가능한 경우는 IoC 컨테이너에 빈으로 등록된 클래스만 가능하다는 것이다.

### 실제 의존성 주입의 실행

스프링에서 @Autowired를 사용했을 때, 실제 의존성 주입을 해주는 당사자는 BeanPostProcessor 구현체인 AutowiredAnnotationBeanPostProcessor이다.

AutowiredAnnotationBeanPostProcessor의 `processInjection` 메서드에서 @Autowired 어노테이션이 사용된 필드, 메서드, 생성자에 대한 객체를 주입해주게 된다.

여기에 @Autowired에 대한 비밀이 숨어 있다. 실제 객체 주입은 `ReflectionUtils`를 사용해서 진행된다는 것이다. 덕분에 private으로 선언된 내부 필드에도 @Autowired 어노테이션을 사용해서 의존성 주입이 가능해지게 되는 것이다.

거기다 생성자나, setter를 통한 의존성 주입을 요구하더라도 해당 클래스의 생성자에 필요한 인수나 setter에 필요한 인수를 파악하기 위해서도 리플렉션을 반드시 사용할 수 밖에 없었는데, 코드를 작성하는 사람의 입장이 아니라 프레임워크의 입장에서도 한 번 생각을 해봤어야 했다.
