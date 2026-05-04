# Sloosh iOS

Минимальная база `SwiftUI`-приложения для iOS-репозитория `Sloosh`.

## Что внутри

- `SlooshIOS.xcodeproj` - проект Xcode, созданный вручную, без необходимости открывать Xcode для генерации файлов.
- `SlooshIOS/` - исходники приложения.
- `.github/workflows/ios-build.yml` - проверка сборки в GitHub Actions на macOS.
- `codemagic.yaml` - минимальная конфигурация для сборки в Codemagic.

## Что проверить перед первым пушем

1. Перед своей подписью обязательно поменяй bundle id в `SlooshIOS.xcodeproj/project.pbxproj` на тот, который соответствует твоему сертификату и provisioning profile.
2. Если хочешь другое отображаемое имя приложения, обнови `INFOPLIST_KEY_CFBundleDisplayName`.
3. Для первой облачной проверки используется сборка на симулятор без подписи.
4. Для сценария с ручной подписью уже добавлен `unsigned archive` под `iphoneos`.
5. Для `ipa` позже понадобится либо экспорт из этого архива, либо отдельная упаковка и твоя последующая подпись.

## Что уже настроено

- `SwiftUI`-жизненный цикл через `@main`.
- `NavigationStack` как база под дальнейшую навигацию.
- Темная тема и стартовый glass-стиль через системные материалы iOS и стандартные SwiftUI-контролы.
- Deployment target: `iOS 18.0`.
- Сборка на актуальном Xcode в облаке.

## Как собирать без Mac

### Вариант 1. GitHub Actions

После пуша в GitHub workflow сам проверит, что проект собирается:

```yaml
xcodebuild -project SlooshIOS.xcodeproj \
  -scheme SlooshIOS \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Это лучший вариант для первого шага: бесплатно, просто и сразу видно, собирается ли шаблон.

Для более близкой к реальному устройству проверки можно вручную запустить `workflow_dispatch`: он соберет `unsigned archive` под `iphoneos` и приложит `SlooshIOS.xcarchive` как artifact.

### Вариант 2. Codemagic

В шаблоне уже есть `codemagic.yaml` с двумя вариантами:

- `ios-sloosh-build` - проверка сборки на симулятор.
- `ios-sloosh-unsigned-archive` - unsigned archive под `iphoneos`.

Важно: `unsigned archive` - это не готовый подписанный `ipa`, а база для дальнейшей упаковки и подписи.

## Следующий шаг

После первого успешного облачного билда можно переносить архитектуру поэтапно:

1. Базовые модели и сетевой слой.
2. Домашний экран.
3. Детали фильма.
4. Поиск.
5. Плеер и авторизация.
