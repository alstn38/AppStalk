# 💰 AppStalk - 앱스토어 클론 앱

- **AppStalk**는 App + Stalk의 합성어로 앱스토어의 앱을 검색하고 다운로드 과정을 클론한 앱입니다.
- 여러 앱을 동시에 다운로드하고 다운로드 상태를 실시간으로 모니터링할 수 있습니다.

<br>

# 🔥주요 기능

### 앱스토어 검색 화면
|   검색   |   다운로드완료   |  중단, 화면전환 상태관리   |
|  :-------------: |  :-------------: |  :-------------: |
| <img width=200 src="https://github.com/user-attachments/assets/292eb845-e3ca-46c8-9831-097495578e65"> |  <img width=200 src="https://github.com/user-attachments/assets/ab04e940-c0fa-45b1-beca-b10573842a1e"> |  <img width=200 src="https://github.com/user-attachments/assets/15320a85-55c0-43f3-844e-8363e5d0afee"> |

- 앱스토어에서 원하는 앱을 검색할 수 있습니다.
- 앱 다운로드 버튼을 통해 다운로드를 시작, 일시정지, 재개할 수 있습니다.
- 다운로드 진행 상황을 원형 프로그레스 바로 시각적으로 확인할 수 있습니다.
- 다운로드가 완료된 앱은 사용자 앱 목록에 자동으로 추가됩니다.
- 네트워크 연결이 끊긴 경우 다운로드가 자동으로 일시정지됩니다.

<br>

### 앱 상세 화면
|   앱 상세화면   | 
|  :-------------: |
| <img width=200 src="https://github.com/user-attachments/assets/0b623793-c932-4d4a-a706-ac9a69f2be27"> | 
- 앱의 상세 정보(버전, 연령, 카테고리, 개발자 등)를 확인할 수 있습니다.
- 릴리즈 노트를 더보기 기능으로 확인할 수 있습니다.
- 앱 스크린샷을 전체화면으로 확대해서 볼 수 있습니다.

<br>


### 사용자 앱 목록 화면
|   앱 목록 화면   | 
|  :-------------: |
| <img width=200 src="https://github.com/user-attachments/assets/f9bd1f3c-418d-4ed8-89a8-7dd89d0bec18"> | 
- 다운로드가 완료된 앱 목록을 확인할 수 있습니다.
- 앱 이름으로 검색하여 원하는 앱을 빠르게 찾을 수 있습니다.
- 스와이프 동작으로 앱을 삭제할 수 있습니다.

<br>

# 🎯 앱 기술 설명

### 멀티 다운로드 타이머 관리

- 개별 앱마다 독립적인 `DownloadTask` 인스턴스를 생성하여 타이머 관리
- `DispatchSourceTimer`를 활용하여 정밀한 시간 측정 및 타이머 제어
- 백그라운드 상태에서도 일관된 타이머 진행을 위한 시간 기반 상태 관리

<br>

### 백그라운드 및 종료 상황 대응

- `UIScene` 라이프사이클 이벤트(`didEnterBackground`, `willEnterForeground`, `willTerminate`)를 활용하여 앱 상태 변화에 대응
- `UserDefaults`를 활용한 앱 종료 시점의 다운로드 상태 영구 저장 및 복원
- 백그라운드 진입 시간과 복귀 시간의 차이를 계산하여 타이머 상태 정확하게 동기화

<br>

### 네트워크 상태 모니터링

- `NWPathMonitor`를 싱글톤 패턴으로 구현하여 앱 전체적인 네트워크 상태 감지
- 네트워크 단절 시 자동으로 모든 다운로드를 일시정지하고 사용자에게 상태 알림
- 네트워크 연결 복구 시 사용자의 선택에 따라 다운로드 재개 지원

<br>

### 상태 동기화 및 옵저버 패턴

- `Combine` 프레임워크의 `PassthroughSubject`를 활용하여 앱 상태 변화 이벤트 발행
- `ViewModelType` 프로토콜을 통한 입력과 출력의 명확한 분리로 MVVM 아키텍처 구현
- 다운로드 상태 변화를 모든 화면에서 실시간으로 반영하여 일관된 사용자 경험 제공
<br>

### 의존성 주입 (Dependency Injection) 패턴 적용

- `DIContainer` 클래스를 통해 객체 간 의존성을 중앙에서 관리하여 결합도를 낮추고 테스트 용이성 향상
- 타입 기반의 의존성 등록 및 해결 메커니즘을 구현하여 코드의 유연성과 확장성 확보
- 서비스 및 레포지토리 레이어의 인터페이스와 구현체를 분리하여 SOLID 원칙 준수

<br>

# 🛠️ 개발 환경

![iOS](https://img.shields.io/badge/iOS-17%2B-000000?style=for-the-badge&logo=apple&logoColor=white)

![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=for-the-badge&logo=swift&logoColor=white)

![Xcode](https://img.shields.io/badge/Xcode-16.3-1575F9?style=for-the-badge&logo=Xcode&logoColor=white)

<br>

# 📅 개발 정보

- ***개발 기간***: 2025.04.24 ~ 2025.04.28
- ***개발인원***: 1명
