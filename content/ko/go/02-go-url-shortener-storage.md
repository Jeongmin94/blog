---
title: "Go로 URL 단축기 만들기 - 2"
date: 2022-08-10T21:20:27+09:00
draft: true
tags:
- url-shortener
categories:
- go
---
데이터를 저장하기 위한 스토리지를 추가해본다.
<!--more-->

# Go로 URL 단축기 만들기 - 2

> https://www.eddywm.com/lets-build-a-url-shortener-in-go-with-redis-part-2-storage-layer/

간단한 기능을 하는 웹 서버도 만들었으니, 이제 서버에 스토리지를 붙일 차례이다. 이전에 웹 프레임워크 `gin`과 함께 Go에서 사용할 수 있는 레디스 클라이언트를 설치했는데, 이것을 이용할 예정이다.

## 1. 저장 서비스 셋업

다음과 같은 프로젝트 디렉토리 구조를 만든다.

```
└── store
    ├── store_service.go
    └── store_service_test.go
```

여기서 `store_service.go`는 레디스를 이용해서 데이터를 저장하는 로직이 들어갈 파일이고, `store_service_test.go`는 `store_service.go`를 위한 유닛 테스트 파일이다.

`store_service.go`에서는 레디스 클라이언트를 직접 사용하는 것이 아니라 래퍼(wrapper) 인터페이스를 만들어 사용할 것이다. 다음과 같이 코드를 작성해주자.

```go
package store

import (
	"context"
	"fmt"
	"github.com/go-redis/redis"
	"time"
)

// Define the struct wrapper around raw Redis Client
type StorageService struct {
	redisClient *redis.Client
}

// Top level declarations for the storeService and Redis Context
var (
	storeService = &StorageService{}
	ctx = context.Background()
)

const CacheDuration = 6 * time.Hour
```

레디스 클라이언트인 `*redis.Client`를 직접 사용하지 않고 `StorageService`라는 래퍼를 만들어 사용하고 있는 것을 볼 수 있다. 이제 실제로 데이터를 저장하기 위한 나머지 로직을 작성한다.

