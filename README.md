coolro-vision-robot-golf-system

* 라즈베리파이에서 사람 추적을 수행하고 STM32 UART로 4륜 로봇을 제어합니다.
* Flutter 앱은 영상 촬영/재생 및 클라우드 저장을 담당하고, 자세 분석은 EC2 MediaPipe로 처리합니다.
* 엣지 센싱, 임베디드 제어, 클라우드 분석까지 연결된 엔드-투-엔드 파이프라인입니다.

Demo
TODO: 라즈베리파이 추적과 자세 피드백이 모두 보이는 GIF/영상 링크 추가

## Problem / Goal
엣지 인식, 임베디드 제어, 클라우드 분석을 하나의 시스템으로 연결하는 것이 목표였습니다.
단발성 데모가 아니라 사용자 앱과 피드백 루프를 가진 실사용 흐름을 만들고자 했습니다.

## System Architecture
```mermaid
graph TD
  A[Flutter App (Smartphone)] -->|Upload video| B[Firebase Storage]
  A -->|POST /analyze| C[EC2 Flask Server]
  C -->|MediaPipe Pose + Feedback| A

  A -->|HTTP| D[Raspberry Pi UI + Local Server]
  D -->|HTTP| A
  D -->|Camera + Ultrasonic| G[Raspberry Pi Tracker]
  D -->|UART 1/2/3/4| E[STM32F103C8T6]
  E -->|PWM + Direction| F[L298N + 4 Motors]
```

## Data Flow / API Flow
Raspberry Pi -> STM32 (UART)
- Command bytes: `1` left, `2` right, `3` forward, `4` stop

Raspberry Pi <-> Flutter App (HTTP)
- 로컬 영상 리스트/재생/업로드 + 스코어 저장 API

EC2 (analysis only)
- 앱에서 자세 피드백이 필요할 때만 `POST /analyze` 호출

EC2 analysis API
- `POST /analyze` (multipart `video` file) -> 분석된 MP4 반환
- `GET /health` -> 상태 확인

## Design Decisions
- 라즈베리파이에서 Pose + 거리 측정: 저지연 로봇 제어를 위해 클라우드 의존을 최소화.
- UART 1바이트 프로토콜: 간단하고 안정적인 임베디드 통신.
- EC2 분석 분리: MediaPipe 연산을 스마트폰/라즈베리파이에서 분리해 앱 부하 감소.
- 라즈베리파이 카메라 공유 파이프라인: UI와 추적이 충돌 없이 동일 프레임 사용.

## Core Logic
1) 초음파 센서가 거리 정보를 주기적으로 갱신
2) Camera Hub가 프레임을 한 번만 처리해 UI와 추적에 공유
3) 위치/거리 기준으로 이동 명령 결정
4) UART 바이트 송신 → STM32 PWM 제어
5) 앱이 선택한 영상을 EC2로 전송 → 피드백 영상 수신

## Responsibility Split
- Perception: 라즈베리파이(포즈/거리), EC2(자세 피드백)
- Planning/Decision: 라즈베리파이에서 좌/우/전진/정지 판단
- Control: STM32가 PWM/방향 신호 생성

## Build & Run
라즈베리파이 추적 (단독 실행)
```bash
cd raspberrypi/test
python3 main.py
```

라즈베리파이 UI + 로컬 HTTP 서버
```bash
cd raspberrypi/test
python3 main_ui.py
```

라즈베리파이 통합 실행 (UI + 로컬 서버 + 추적 + UART)
```bash
cd raspberrypi/test
python3 main_full.py
```

EC2 분석 서버
```bash
cd ec2_golf_server
pip install -r requirements.txt
python app.py
```

STM32 펌웨어 (HAL)
- `stm32_f103_hal/main.c`
- USART1: PA9/PA10, 9600 baud
- PWM: TIM2 CH1/CH2 (PA0/PA1)
- L298N IN1..IN4: PB12..PB15

Flutter 앱 (스마트폰)
```bash
cd flutter_app
flutter pub get
flutter run
```

## Config / Parameters
라즈베리파이 설정: `raspberrypi/test/config.yaml`
- `distance_threshold_cm`: 전진/정지 거리 임계값
- `center_tolerance_px`: 좌/우 판단 여유값
- `message_interval_s`: UART 송신 주기
- `echo_timeout_s`: 초음파 타임아웃

## Metrics / Results
TBD: 성공률, 평균 반응 시간, 분석 처리량 등 추가

## Failure Analysis
TBD: 자주 발생하는 실패와 대응 전략 작성
- 가장 많이 실패한 단계:
- 주요 실패 원인:
- 복구 효과:

## Real-world Considerations
- 조명/모션 블러는 포즈 인식 안정성에 영향
- L298N 전류 한계로 토크가 낮음 (드라이버 교체 필요)
- 전원 리플/노이즈가 UART에 영향을 줄 수 있음

## Limitations
- 자세 피드백은 각도 임계값 기반의 휴리스틱
- 스윙 단계 분리(백스윙/다운스윙) 없음
- 서버 저장소는 인증/보존 정책 없음

## Portfolio Summary
엣지 인식, 임베디드 제어, 클라우드 분석을 하나의 시스템으로 통합한 프로젝트입니다.
간단한 프로토콜 설계와 안정적인 파이프라인 구성 능력을 보여줍니다.
구조화된 모듈과 명확한 데이터 흐름으로 확장성과 재현성을 확보했습니다.

## Roadmap / Next Steps
- 스윙 단계 인식 및 피드백 고도화
- EC2 인증 및 저장 정책 추가
- L298N 대신 고전류 모터 드라이버 적용
