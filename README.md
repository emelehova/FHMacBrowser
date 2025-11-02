# FHMacBrowser (легкий браузер для слабых macOS)

## Особенности
- WKWebView + агрессивные оптимизации: блокировка изображений/медиа/шрифтов, убийство CSS-анимаций, троттлинг requestAnimationFrame, lazy-медиа.
- Непостоянный профиль (`--temp-profile`) — без дискового кэша/куки.
- Режимы: `--lite`, `--lazy-media`, `--block-assets`, `--mobile`, `--kiosk`, `--ws-batch=50`.
- UA-подмена и «мобильный» режим для более лёгких версий сайтов.
- Single-instance лок и защита от сна.

## Быстрый старт
1. Откройте папку `FHMacBrowser` в Xcode: **File → New → Project… → App (macOS)**  
   - Product Name: `FHMacBrowser`  
   - Interface: SwiftUI, Language: Swift  
   - Сохраните проект в корень репозитория, чтобы появился `FHMacBrowser.xcodeproj`.  
   - Добавьте в таргет все файлы из папки `FHMacBrowser/` (App.swift, ContentView.swift, WebView.swift, BrowserController.swift, Scripts.swift, Power.swift, Info.plist).

2. Запуск:
   - В Scheme → Run → Arguments добавьте, например:  
     `--start=https://lite.youtube.com --lite --lazy-media --block-assets=img,media,fonts --mobile --kiosk --ws-batch=50 --temp-profile`
   - Соберите и запустите.

3. Сборка CI (GitHub Actions):
   - Пуш в ветку `main`.  
   - Артефакт с `.app` появится в Actions.

## Флаги запуска
- `--start=<url>` — стартовый адрес (по умолчанию `about:blank`)
- `--lite` — отключить CSS-анимации, троттлинг RAF (~30fps)
- `--lazy-media` — лениво грузить `img/iframe/video/audio`
- `--block-assets=img,media,fonts` — блокировать категории ресурсов
- `--mobile` — мобильный UA и viewport
- `--kiosk` — полноэкранный режим
- `--ws-batch=<ms>` — буферизация входящих WebSocket-сообщений
- `--temp-profile` — `WKWebsiteDataStore.nonPersistent()`
- `--keep-awake` — запрет сна macOS, пока работает приложение

## Лицензия
MIT
