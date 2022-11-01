---
title: "Go로 URL 단축기 만들기 - 1"
date: 2022-08-08T21:02:20+09:00
draft: true
tags:
- url-shortener
categories:
- go
---
Go로 URL 단축기 만들어 본다.
<!--more-->

# Go로 URL 단축기 만들기 - 1

> https://www.eddywm.com/lets-build-a-url-shortener-in-go/

URL 단축기는 복잡하고 긴 URL을 짧게 만들어 공유하기 쉽게 만들어 주는 서비스다. https://tinyurl.com/app와 같은 URL 단축 사이트부터 조금 더 생각해보면 다양한 사용처가 생길 것 같은 느낌이 든다. 어쨌든 지금은 Go를 조금 더 사용해보려고 URL 단축기를 만들어 볼 것이다. 추가적인 활용 방안 등은 추후에 생각해보자.

## 1. 프로젝트 셋업하기

Go로 URL 단축기를 만들어야 하기 때문에 Go 설치가 필요하다. 1.11 버전 이상의 Go를 설치해주자. Go는 공식 문서가 굉장히 깔끔하게 정리되어 있다. 공식 문서를 통해 어렵지 않게 Go를 설치할 수 있다.

> https://go.dev/doc/install

이렇게 Go를 설치하고 나서 `go mod` 명령을 통해 프로젝트를 이니셜라이징 하라고 원글에 작성되어 있다. `go mod`가 무엇인지 모르겠다. 찾아보자.

```bash
go mod init github.com/your-username/go-url-shortener
```

### go mod ?

> go mod에 대한 참조글
>
> https://jbhs7014.tistory.com/182

모듈에 대한 간단한 개념은 다음과 같다고 보면 될 것 같다.

> 1.11 이전 버전의 Go에서는 `GOPATH`와 `GOROOT`라는 환경 변수를 통해 패키지의 의존성을 관리했다고 한다. 이는 곧 Go로 만든 프로젝트가 환경 변수에 등록된 경로가 아니면 프로젝트를 만들어 실행하기 어렵다는 것을 의미하게 되는데, 이러한 불편함을 해소하기 위해 1.11 버전부터 모듈이라는 개념이 등장하게 된다.
>
> 모듈 도입으로 인해 github과 같은 형상 관리 도구 툴을 통해 다른 사람과 코드 공유가 용이해졌고, 로컬에서도 굳이 힘들게 경로를 찾고 지정하지 않아도 모듈을 사용하면 간단하게 필요한 패키지를 import 하여 의존성을 쉽게 관리할 수 있게 됐다.

그렇다면 이어서 기존의 `GOPATH`와 `GOROOT`를 사용하는 방식이 어땠는지 살펴볼 필요가 있을 것이다. 그래야 모듈이 편리한 이유를 알 수 있을 것 같다.

#### GOPATH 패키지 및 의존성 관리

Go를 설치하고 `go env`라는 명령어를 사용하면 Go에서 사용하는 다양한 환경 변수가 화면에 나타난다. 여기에는 당연히 `GOPATH`와 `GOROOT`도 포함된다.

```bash
go env
...
GOPATH="/Users/me/go"
...
GOROOT="/usr/local/go"
...
```

여기서 `GOROOT`는 내가 사용할 Go 관련 도구들이 설치된 위치이고, `GOPATH`는 내가 작성하고 있는 Go로 만든 프로그램의 위치를 의미한다. Go에서는 `go get` 명령어를 통해 패키지를 설치할 수 있는데, 설치되는 패키지의 소스코드는 `GOPATH`의 하위 경로인 `GOPATH/src`에 저장이 된다. 

```bash
GOPATH
    /bin
    /pkg
    /src
```

기본적인 `GOPATH`의 구조는 위와 같이 `bin`, `pkg`, `src`로 구성된다. 각각의 역할은 다음과 같다.

- bin : 컴파일을 통해 만들어진 실행가능한 형태의 파일이 bin에 위치하게 된다.
- pkg : 소스코드를 컴파일할 때 생성되는 라이브러리 패키지가 pkg에 위치하게 된다. `<OS>_<Architecture>` 형태로 저장된다.
- src : 소스코드와 `go get`으로 받아온 패키지의 소스코드가 위치하게 된다.

모듈이 없는 시절에는 모든 소스코드가 `GOPATH/src`에 위치해야 했다. 이때, `src` 하위에 저장되는 패키지 경로가 Go 내부에서 사용할 패키지의 이름이 된다.

```go
package main

import (
    "fmt"
    "github.com/me/ServerA"
)

func main() {
    fmt.Println("hello world")
    s := ServerA.New()
}
```

위의 코드를 보면 `fmt`와 `ServerA` 패키지를 import 해서 사용하고 있는 것을 볼 수 있다. 모듈이 없기 때문에 위의 패키지는 `GOPATH/src` 경로에 위치하고 있을 것이다. 실제로 `ServerA` 패키지는 `GOPATH/src/ServerA`에 존재하고 있을 것이다. 여기서 `github.com/me`로 import가 되는 이유는, `ServerA`가 github을 통해 관리되고 있음을 나타내기 위함이다. import에 입력한 github url을 통해 패키지의 버전 관리 및 소스코드 관리를 할 수 있게 되는 것이다.

반면, `fmt`는 Go 설치와 함께 설치된 내장 라이브러리이기 때문에 `GOROOT`의 `src`에 저장되어 있어 우리가 `go get`으로 패키지를 설치하지 않아도 사용할 수 있다.

어쨌든 여기서 중요한 것은 모듈이 없는 상황에서는 `GOPATH` 하위에 모든 프로젝트가 존재해야 한다는 것이다. 프로젝트 자체가 `GOPATH`에 의존적이게 만들어질 수 밖에 없고, `GOPATH/src` 내부에 있는 여러 패키지들이 서로에게 영향을 주는 상황도 발생하게 될 것이다.

### 모듈의 등장

Go의 모듈은 `GO111MODULE`이라는 환경 변수를 통해 사용 여부를 설정할 수 있다.(`go env` 명령어로 상태 확인 가능) 모듈을 사용하면 `GOPATH`가 아닌 경로에서도 프로젝트를 만들고 빌드할 수 있다.

모듈을 만들 때 중요한 것은 `go.mod` 파일이 된다. `go.mod` 파일에는 현재 프로젝트에서 의존성을 가지는 패키지 목록이 저장된다. 즉, `GOPATH/src`에 종속적인게 아니라 `go.mod`에 패키지 목록을 저장하여 파일로 관리하게 되는 것이다.

따라서 모듈을 사용하는 경우에는 프로젝트 시작과 함께 `go.mod` 파일을 만들기 위해 `go mod init <module_name>` 명령을 실행해야 하는 것이다. 이제 다시 위에서 입력한 이니셜라이징 명령어를 보자.

```bash
go mod init github.com/your-username/go-url-shortener
```

`go mod init` 명령어를 통해 `go.mod` 파일을 만들었고, 해당 모듈의 이름은 `github.com`으로 시작하는 레포지토리 주소로 되어있다. 프로젝트를 진행하면서 해당 프로젝트를 github을 통해 관리한다면, `github/<user_name>/<repo_name>` 형식으로 사용해야 하기 때문에 이렇게 작성해준 것이라고 볼 수 있다. 이렇게 생성된 초기 `go.mod`에는 다음과 같은 내용만 작성되어 있다.

```
module github.com/your-username/go-url-shortener

go 1.18
```

여기에 이제 URL 단축기에 필요한 의존성들을 `go get` 명령어를 통해 설치해주자.

```bash
# go용 redis 클라이언트
go get github.com/go-redis/redis/v8
# go용 웹 프레임워크
go get -u github.com/gin-gonic/gin
```

설치를 하고 나서 다시 `go.mod` 파일을 보면 다양한 패키지들이 설치된 것을 확인할 수 있다.

```
module github.com/Jeongmin94/go-url-shortener

go 1.18

require (
	github.com/cespare/xxhash/v2 v2.1.2 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/gin-contrib/sse v0.1.0 // indirect
	github.com/gin-gonic/gin v1.8.1 // indirect
	github.com/go-playground/locales v0.14.0 // indirect
	github.com/go-playground/universal-translator v0.18.0 // indirect
	github.com/go-playground/validator/v10 v10.11.0 // indirect
	github.com/go-redis/redis/v8 v8.11.5 // indirect
	github.com/goccy/go-json v0.9.10 // indirect
	github.com/json-iterator/go v1.1.12 // indirect
	github.com/leodido/go-urn v1.2.1 // indirect
	github.com/mattn/go-isatty v0.0.14 // indirect
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v1.0.2 // indirect
	github.com/pelletier/go-toml/v2 v2.0.2 // indirect
	github.com/ugorji/go/codec v1.2.7 // indirect
	golang.org/x/crypto v0.0.0-20220722155217-630584e8d5aa // indirect
	golang.org/x/net v0.0.0-20220805013720-a33c5aa5df48 // indirect
	golang.org/x/sys v0.0.0-20220804214406-8e32c043e418 // indirect
	golang.org/x/text v0.3.7 // indirect
	google.golang.org/protobuf v1.28.1 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
)
```

## 2. 웹 서버 시작하기

이제 프로젝트를 위해 필요한 기본적인 세팅은 끝났다. 조금 전에 설치한 웹 프레임워크를 이용해서 간단한 웹 서버를 실행해보자. `main.go` 파일을 만들어 주고 다음과 같이 코드를 작성한다.

```go
package main

import (
	"fmt"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Hey Go URL Shortener !",
		})
	})

	err := r.Run(":9808")
	if err != nil {
		panic(fmt.Sprintf("Failed to start the web server - Error: %v", err))
	}
}
```

`go run main.go`를 입력해서 서버를 실행하고 브라우저에서 `localhost:9808`을 입력하면 `"message": "Hey Go URL Shortener !"`라는 문자를 확인할 수 있을 것이다. `gin`은 Go의 대표적인 웹 프레임워크로 간단하게 웹 서비스를 만들 수 있게 도와준다.

`gin.Default()`를 사용하면 logger와 recovery 미들웨어를 가진 기본적인 router를 사용할 수 있는데, 이를 통해 HTTP 메서드에 맞는 라우팅 경로를 만들 수 있다. 위의 코드에서는 root 경로에 HTTP 메서드 GET을 매핑시켜 서버가 시작하는 9808 포트의 root로 들어오는 요청을 받는 라우터를 만든 것이다.

