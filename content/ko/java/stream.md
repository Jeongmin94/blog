---
title: "스트림"
date: 2022-09-25T16:07:27+09:00
draft: false
tags:
- stream, java8
categories:
- java
---
자바 8 람다식 해설서를 읽어본다.
<!--more-->

# 자바 8 람다식 해설서 - 스트림과 함수형 인터페이스

## 1. 스트림이란?

스트림은 데이터의 집합(배열이나 컬렉션 등)에 대한 처리를 함수형 프로그래밍으로 간결하게 기술하기 위한 새로운 개념이다. 람다식은 이 스트림을 최대한 효과적으로 사용하기 위해 도입된 것이라 해도 과언이 아니다.

프로그래밍에서 스트림이라는 개념은 데이터의 흐름을 의미하는데, 자바에서도 `java.io` 패키지의 파일IO에서 데이터의 흐름을 스트림이라고 표현하고 있다. 그러나 자바 8에서 추가된 스트림은 이와는 전혀 다르다는 것을 알고 있어야 한다.

자바 8에서는 `java.util.stream` 패키지에 스트림 API라고 불리는 클래스와 인터페이스가 준비되어 있다. 스트림의 시작은 배열이나 컬렉션 등의 데이터 집합으로부터 스트림 오브젝트를 취득하는 것이다.

스트림 오브젝트는 다음과 같은 4가지의 인터페이스형 중 하나이다. 그리고 이들 4개의 인터페이스는 슈퍼 인터페이스로 BaseStream 인터페이스를 계승하고 있다.

- Stream<T>
- IntStream
- LongStream
- DoubleStream

`Stream<T>`의 형태를 가진 스트림 오브젝트는 제네릭 타입의 데이터 집합을 취급한다. 나머지 `IntStream`, `LongStream`, `DoubleStream` 스트림 오브젝트는 기본 데이터형을 취급한다.

### 스트림 오브젝트의 취득 방법

스트림 오브젝트 취득에서 가장 자주 사용하는 것이 List나 Set 등의 컬렉션(Map 제외)이 가진 스트림 메서드를 사용하는 것이다.

Map을 제외한 컬렉셕(List나 Set 등)은 `java.util.Collection`을 계승하고 있는데, 컬렉션 인터페이스는 디폴트 메서드로 stream 메서드를 가지고 있다.

```java
public interface List<E> extends Collection<E> {}
public interface Set<E> extends Collection<E> {}

// Collection
default Stream<E> stream() {
    return StreamSupport.stream(spliterator(), false);
}

// 스트림 오브젝트 취득하기
List<String> list = Array.asList("A", "B", "C");
Stream<String> strema = list.stream();
```
배열에서 스트림 오브젝트를 취득하는 방법은 다음과 같다.

```java
String[] arr1 = {"A", "B", "C"};
Stream<String> stream1 = Arrays.stream(arr1);

int[] arr2 = {1,2,3};
IntStream stream2 = Arrays.stream(arr2);

long[] arr3 = {1L, 2L, 3L};
LongStream stream3 = Arrays.stream(arr3);
```
`Arrays.stream` 메서드는 인수로 들어오는 배열의 타입에 따라 적절한 스트림 오브젝트를 반환한다.

자바 8에서는 인터페이스에 static 메서드를 사용할 수 있는데, 스트림 인터페이스가 가진 static of 메서드를 사용해서 직접 스트림 오브젝트를 생성하는 것도 가능하다.

```java
// of 메서드
// values는 가변장인수이기 때문에 같은 타입의 인수를 여러개 받을 수 있다.
public static<T> Stream<T> of(T... values) {
    return Arrays.stream(values);
}

Stream<String> stringStream = Stream.of("A", "B", "C");
IntStream intStream = IntStream.of(1, 2, 3);
LongStream longStream = LongStream.of(1L, 2L, 3L);
```

이와 같이 스트림 오브젝트를 취득하고, 이를 람다식을 이용해 데이터의 변환이나 추출을 수행할 수 있는 것이 스트림의 기본적인 흐름이라 할 수 있다.

## 2. 대표적인 함수형 인터페이스

함수형 인터페이스는 하나의 추상 메서드를 가진 인터페이스다. 그리고 자바 8에서는 java.util.function 패키지에 범용적으로 이용가능한 43개의 함수형 인터페이스가 추가되었는데, 일반적으로 람다식을 표현하는 함수 오브젝트는 이 43개의 함수형 인터페이스 중 하나라고 볼 수 있다.

43개의 함수형 인터페이스 중에서 핵심적인 것은 7개가 있고, 나머지는 그 7개의 파생형이라고 할 수 있기 때문에 7개의 대표 함수형 인터페이스에 대해서 살펴보고 넘어가는 것이 좋다.

### Supplier<T> 인터페이스

```java
@FunctionalInterface
public interface Supplier<T> {

    /**
     * Gets a result.
     *
     * @return a result
     */
    T get();
}
```

인수가 없는 T 타입의 값을 반환하는 `get`을 가지고 있는 Supplier<T> 인터페이스는 공급자라는 의미에 맞게 아무것도 인수를 받지 않아도 `get` 메서드를 통해 오브젝트를 받아올 수 있는 추상 메서드를 가지고 있다.

스트림 인터페이스에는 Supplier 인터페이스형을 인수로 가진 generate 메서드나 collect 메서드가 있다.

```java
Stream<Double> stream = Stream.generate(() -> Math.random());
```

generate 메서드는 스트림 인터페이스의 static 메서드다. 위의 코드에서는 `Math.random()`을 Supplier로 사용하여 0.0에서 1.0 미만의 값을 랜덤으로 반환하게 만들었다.

generate 메서드는 Math 클래스의 random 메서드를 무제한 호출한다. 이는 개념적으로 무한개의 데이터를 가진 스트림이 되는 것이지만, 실제로는 스트림 인터페이스가 가진 limit 메서드를 이용해서 개수를 특정할 수 있다. 따라서 다음과 같이 코드를 수정하면 0.0 이상, 1.0 미만인 랜덤값을 1억개 가지고 있는 스트림 오브젝트를 획득할 수 있게 된다.

```java
Stream<Double> stream = Stream.generate(() -> Math.random()).limit(100000000);
```

Supplier 인터페이스의 기본 타입 특화형 인터페이스는 다음과 같다.

- BooleanSupplier
- IntSupplier
- LongSupplier
- DoubleSupplier

### Consumer<T> 인터페이스

```java
@FunctionalInterface
public interface Consumer<T> {

    /**
     * Performs this operation on the given argument.
     *
     * @param t the input argument
     */
    void accept(T t);
```

Consumer 인터페이스는 인수로 받은 오브젝트를 소비하고 어떠한 값도 반환하지 않는 accept 추상 메서드를 가지고 있다. Suppiler와는 정반대의 기능을 하는 것이다.

스트림 인터페이스에는 Consumer 인터페이스를 인수로 받는 forEach나 peek 메서드가 있다.

```java
IntStream.of(1,2,3)
        .forEach(System.out::println);
```

### Predicate 인터페이스

```java
@FunctionalInterface
public interface Predicate<T> {

    /**
     * Evaluates this predicate on the given argument.
     *
     * @param t the input argument
     * @return {@code true} if the input argument matches the predicate,
     * otherwise {@code false}
     */
    boolean test(T t);
```

Predicate 인터페이스는 T 타입 인수를 테스트하는 test 추상 메서드를 가지고 있다. predicate의 뜻은 술어로, test 메서드를 통해 인수로 받은 오브젝트의 진위 판정을 할 수 있다.

스트림 인터페이스에서는 filter나 allMatch, anyMatch, nonMatch 등의 메서드가 Predicate 인터페이스를 받는다.

```java
Predicate<String> p = s -> s.length() >= 3;
List<String> list = Arrays.asList("ABC", "DE", "FGHI");

// 모두 조건을 만족하는지
boolean all = list.stream().allMatch(p);
// 어떤 것이라도 조건을 만족하는지
boolean any = list.stream().anyMatch(p);
// 모두 조건을 만족하지 않는지
boolean none = list.stream().noneMatch(p);
```

### Function<T, R> 인터페이스

```java
@FunctionalInterface
public interface Function<T, R> {

    /**
     * Applies this function to the given argument.
     *
     * @param t the function argument
     * @return the function result
     */
    R apply(T t);
```

Function 인터페이스는 T 타입 인수를 처리하고, 결과로 R 타입 오브젝트를 리턴하는 apply 추상 메서드를 가지고 있다. 데이터의 가공 및 변환을 표현하고 있는 중요한 인터페이스다.

스트림 인터페이스의 map, flagMap 메서드는 인수로 Function 인터페이스를 받는다.

```java
Stream.of(1,2,3,4,5)
        .map(num -> Integer.toString(num));
```

### BiFunction(T, U, R) 인터페이스

```java
@FunctionalInterface
public interface BiFunction<T, U, R> {

    /**
     * Applies this function to the given arguments.
     *
     * @param t the first function argument
     * @param u the second function argument
     * @return the function result
     */
    R apply(T t, U u);
```

BiFunction 인터페이스는 T와 U 타입의 인수를 받아 결과로 R을 리턴하는 apply 추상 메서드를 가지고 있다. Function 인터페이스의 특수화된 버전이라고 볼 수 있다.

### UnaryOperator 인터페이스

```java
@FunctionalInterface
public interface UnaryOperator<T> extends Function<T, T> {

    /**
     * Returns a unary operator that always returns its input argument.
     *
     * @param <T> the type of the input and output of the operator
     * @return a unary operator that always returns its input argument
     */
    static <T> UnaryOperator<T> identity() {
        return t -> t;
    }
```

UnaryOperator 인터페이스는 Function 인터페이스의 서브 인터페이스로, 인수의 타입과 반환타입이 동일한 경우(`Function<T, T>`)를 표현하는 인터페이스다.

스트림 인터페이스에는 UnaryOperator 인터페이스를 인수로 받는 iterate 메서드가 있다.

```java
Stream.iterate(1, x -> x*10)
        .limit(5)
        .forEach(System.out::println);
```

### BinaryOperator 인터페이스

```java
@FunctionalInterface
public interface BinaryOperator<T> extends BiFunction<T,T,T>
```

BinaryOperator 인터페이스는 BiFunction 인터페이스의 서브 인터페이스로, 2개의 인수 타입과 반환 타입이 모두 동일한(`BiFunction<T, T, T>`)를 표현하는 인터페이스다.

따라서 BinaryOperator<T> 인터페이스는 2개의 T 타입 인수를 처리하고, 결과로 동일한 T 타입의 값을 반환하는 추상메서드 apply를 개념적으로 가지고 있다.

## 3. 스트림의 특징

이제 본격적으로 스트림에 대해 알아 볼 차례이다. 스트림을 사용한 데이터 조작의 기본적인 스텝은 다음과 같다.

1. 배열이나 컬렉션 등의 데이터 집합으로부터 스트림 오브젝트를 취득
2. 스트림 오브젝트에 대해서 중간조작을 적용
3. 스트림 오브젝트에 대해서 종단조작을 적용

중간조작은 데이터의 변환 및 추출 등을 수행해서 새로운 스트림 오브젝트를 반환하는 메서드를 의미한다. 중간조작을 통해 새로운 스트림 오브젝트를 반환하기 때문에 중간조작 메서드를 연속적으로 호출할 수 있다.

종단조작은 스트림의 최종적인 결과를 생성하기 위해서 마지막에 한번 부르는 메서드를 말한다. 최종적인 결과이기 때문에 새로운 컬렉션이나 합계, 평균, 최대 등 다양한 값을 받을 수 있으며, 스트림이 끝나게 된다.

```bash
최종결과 = 스트림 오브젝트
            .중간조작 메서드1
            .중간조작 메서드2
            .중간조작 메서드3
            .종단조작 메서드
```

이처럼 스트림 오브젝트에 대한 데이터의 변환이나 추출 등을 수행할 수 있지만, 스트림 오브젝트 취득을 위한 원본 데이터 집합에는 어떠한 영향을 끼치지 않는다. 그리고 중간조작은 종단조작이 실행된 시점에서 처음으로 실행된다. 즉, 중간조작 메서드에 건내진 람다식은 즉시 실행되는 것이 아니라 나중에 일괄로 실행된다.(지연평가)

마지막으로 4개의 스트림 인터페이스는 모두 java.lang.AutoCloseable 인터페이스를 계승하고 있다. 즉, 파일 IO나 데이터베이스와 같인 Close의 개념이 존재하는데, 스트림 오브젝트는 종단조작 메서드를 실행하면 Close가 된다. 종단조작 메서드를 사용해서 닫혀버린 스트림은 재사용이 불가능하다.

## 4. 대표적인 종단조작 메서드

스트림 오브젝트는 반드시 1번의 종단조작 메서드를 호출하고, 최종 결과물을 얻어야 한다. forEach나 allMatch, anyMatch, nonMatch 메서드도 종단조작 메서드다.

### 종단조작 count 메서드

4개의 스트림 인터페이스는 모두 인수없이 long 타입을 반환하는 count 메서드를 가지고 있다. count 메서드는 스트림이 보유한 데이터의 개수를 반환한다.

```java
Stream.of(1,2,3,4,5)
    .count()
```

### 종단조작 max, min 메서드

Stream 인터페이스는 Comparator<? super T> 타입의 인수를 받아 Optional<T>를 리턴하는 max, min 메서드를 가지고 있다. Comparator 인터페이스의 기준에 따라 스트림의 데이터 집합의 최대값과 최소값을 반환한다.

```java
List<String> list1 = Arrays.asList("ABC", "DE", "EFGH", "J");
String max = list1.stream()
        .max((x, y) -> x.length() - y.length())
        .orElse("최대값 없음");

String min = list1.stream()
        .min((x, y) -> x.length() - y.length())
        .orElse("최소값 없음");

System.out.println(max);
System.out.println(min);
```

### 종단조작 sum, average 메서드

기본타입에 대한 스트림 인터페이스는 모두 sum, average 메서드를 가지고 있다.

```java
int sum = IntStream.of(1, 2, 3, 4, 5)
        .sum();
```

### 종단조작 reduce 메서드

```java
Optional<T> reduce(BinaryOperator<T> accumulator);
T reduce(T identity, BinaryOperator<T> accumulator);
```

reduce 메서드는 데이터 집합을 하나로 집약할 수 있는 종단조작 메서드이다. count, max, min, sum, average 메서드를 호출하면 여러 데이터 집합이 스트림에 있지만, 하나의 결과값으로 출력되는 것을 확인할 수 있었다. 이 메서드들은 특수화된 reduce 메서드라고 볼 수 있는 것이다.

우선 인수가 하나인 reduce 메서드를 살펴보자.

```java
List<String> list = Arrays.asList("A", "B", "C", "D", "E");
Optional<String> optional = list.stream()
        .reduce((x, y) -> x + y);

System.out.println(optional.orElse(""));
```

출력결과는 `ABCDE`다. reduce 메서드의 인수로 들어간 람다식 `(x, y) -> x + y`는 문자열의 연결을 표현하고 있다. 이에 따라 `A`와 `B`를 연결해 `AB`를 만들고, 여기에 `C`를 연결해 `ABC`를 만들어 간다.

스트림 오브젝트가 보유한 데이터가 0개인 경우에는 이렇게 accumulator에 들어갈 값이 없기 때문에 Optional을 리턴하는데, 이것이 불편하다면 인수가 2개인 reduce를 사용하면 된다.

```java
List<String> list = Arrays.asList("A", "B", "C", "D", "E");
String reduce = list.stream()
        .reduce("", (x, y) -> x + y);
System.out.println(reduce);
```

첫 번째 인수은 identity는 accumulator에 들어갈 초기값을 의미한다. 따라서 스트림의 데이터 집합 개수가 0개라도 identity를 반환하면 되기 때문에 Optional을 리턴할 필요가 없어진다.

### 종단조작 collect 메서드

collect 메서드는 스트림 요소에 대해서 가변 리덕션 조작을 실행한다. 스트림 인터페이스에서 collect 메서드는 다음과 같이 정의되어 있다. 

```java
<R> R collect(
    Supplier<R> supplier,
    BiConsumer<R, ? super T> accumulator,
    BiConsumer<R, R> combiner);
```

T 타입은 스트림이 가진 개개의 데이터 타입, R 타입은 가변 컨테이너의 타입이다. 각 인수의 역할은 다음과 같다.

- supplier: R 타입의 데이터를 저장할 수 있는 가변 컨테이너를 생성하는 람다식을 사용한다.
- accumulator: 가변 컨테이너에 T 타입의 스트림 데이터를 저장할 수 있도록 하는 람다식을 사용한다.
- combiner: 여러개의 가변 컨테이너를 어떻게 합칠지 기술한다.(병렬처리가 아니면 실행되지 않음)

문자열 스트림을 ArrayList로 옮기는 예제를 보면 이해가 쉬울 것이다.

```java
Stream<String> stream = Stream.of("A", "B", "C", "D", "E");
ArrayList<String> list = stream.collect(
        () -> new ArrayList<String>(),      // 가변 컨테이너 ArrayList<String> 생성하는 람다식
        (l, str) -> l.add(str),             // 가변 컨테이너에 스트림의 데이터를 추가하는 방식 기술
        (l1, l2) -> l1.addAll(l2)           // 여러 가변 컨테이너를 통합하는 방식 기술
);

list.stream()
        .forEach(System.out::println);
```

이렇게 collect 메서드를 사용하면 스트림의 데이터를 가변 컨테이너로 옮기는 리덕션 조작을 할 수 있는데, 세 개의 람다식을 일일이 작성하는 것이 어렵게 느껴지기도 하고, 까다롭게 느껴지기도 한다. 그렇기 때문에 collect 메서드에는 인수가 하나인 오버로드가 있다.

```java
<R, A> R collect(Collector<? super T, A, R> collector);
```

인수로 들어오는 java.util.Collector<T, A, R> 인터페이스는 세 개의 람다식을 하나로 묶어 놓은 것이다. 결국 세 개의 람다식을 또 만들어야 되냐고 생각할 수 있지만 java.util.Collectors 클래스에 미리 구현된 Collector 인터페이스가 여러개 준비되어 있다. 이것을 이용하면 더욱 간단하게 문자열 스트림을 ArrayList로 옮길 수 있다.

```java
Stream<String> stream = Stream.of("A", "B", "C", "D", "E");
List<String> list = stream.collect(Collectors.toList());

list.stream()
        .forEach(System.out::println);
```

list 외에도 다양한 형식으로 collect 메서드를 사용할 수 있는 Collectors.collect 메서드가 준비되어 있기 때문에 자세한 내용은 도큐먼트를 참고하면 되겠다.

## 5. 대표적인 중간조작 메서드

중간조작 메서드는 스트림의 데이터에 대한 변환, 추출 등을 진행하고 또 다른 스트림을 반환한다. 덕분에 중간조작 메서드는 여러 번 연속해서 사용할 수 있다.

### 중간조작 filter 메서드

filter 메서드는 이름 그대로 필터링을 한다.

```java
Stream<String> stream = Stream.of("ABC", "DE", "FGH");
List<String> collect = stream.filter(s -> s.length() >= 3)
        .collect(Collectors.toList());

collect.forEach(System.out::println);
```

filter 메서드는 인수로 Predicat 인터페이스를 받는다. 인수로 들어오는 데이터가 특정 조건을 만족하는 경우에만 필터링이 되기 때문에 위의 코드에서는 `ABC`, `FGH`와 같이 길이가 3 이상인 문자열 데이터만 남게 된다.

### 중간조작 map 메서드

map 메서드는 스트림의 데이터를 새로운 스트림 오브젝트로 반환한다. 즉, 매핑 작업을 하는 것인데, 스트림의 데이터를 가공하여 새로운 데이터 집합을 생성하는 것이다.

```java
Stream<String> stream = Stream.of("ABC", "DE", "FGH");
List<String> collect = stream.map(String::toLowerCase)
        .collect(Collectors.toList());

collect.forEach(System.out::println);
```

map의 인수로 Function 인터페이스가 들어가는데, 스트림의 데이터 집합 타입을 받아 새로운 값으로 리턴해준다. 위의 코드에서는 대문자가 소문자로 변환되었기 때문에 String -> String으로 타입은 같지만 값의 조작이 진행되었다.

이번에는 문자열을 길이로 변경하는 map을 사용해보자.

```java
Stream<String> stream = Stream.of("ABC", "DE", "FGH");
List<Integer> list = stream.map(String::length)
        .collect(Collectors.toList());

list.forEach(System.out::println);
```

문자열을 길이로 변환했기 때문에 반환되는 List의 타입의 Integer인 것을 확인할 수 있다. 즉, map을 통해 Stream<Integer> 오브젝트가 만들어진 것이다.

Integer의 경우 int의 박싱 타입이기 때문에 연산에서 손해를 볼 수 있다. 따라서 이런 경우에는 기본 타입을 가지는 스트림으로 변환시키기 위해 mapTo{PrimitiveType} 메서드를 사용해볼 수 있다.

```java
Stream<String> stream = Stream.of("ABC", "DE", "FGH");
IntStream intStream = stream.mapToInt(String::length);
System.out.println(intStream.max());
```

mapToInt 메서드를 사용하면 기본 정수 타입은 IntStream 오브젝트를 리턴하기 때문에 박싱, 언박싱으로 인한 손해를 줄일 수 있으며, 기본 타입 스트림에서 제공하는 sum, max와 같은 메서드도 사용할 수 있게 된다.

### 중간조작 sorted 메서드

sorted 메서드는 스트림의 데이터를 정렬시킨 상태로 반환한다. 기본 타입의 스트림 오브젝트는 숫자의 크기 순으로 정렬이 진행되지만, 참조 타입의 데이터를 가진 Stream<T> 오브젝트에서는 Comparable 인터페이스를 구현해야 한다.

```java
Stream<String> stream = Stream.of("ABC", "DE", "FGH");

stream.sorted()
        .forEach(System.out::println);
```

문자열의 경우 알파벳 순으로 정렬이 되어 출력된다. Comparator를 사용하여 알파벳 순이 아니라 길이 순으로 정렬을 하는 경우는 다음과 같다.

```java
Stream<String> stream = Stream.of("ZXC", "ABC", "DE", "FGH");

stream.sorted((s1, s2) -> s1.length() - s2.length())
        .forEach(System.out::println);
```