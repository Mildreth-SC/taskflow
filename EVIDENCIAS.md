# Evidencias — Sesión 1

Captura real del emulador. No es el teléfono físico de Mildreth Guanoluisa y no sustituye una foto que el aula pida desde ese teléfono.

## Entorno

Tomada el 7 de noviembre de 2026 en un entorno remoto de prueba.

- Flutter 3.47.9 y Dart 3.13.7 (el `pubspec.yaml` de este repo pide SDK `^3.13.7`)
- Android Emulator, imagen `system-images;android-35;google_apis;x86_64` (Android 15, API 35)
- AVD `taskflow_api35`, 1080×2400, dispositivo `emulator-5554`
- Paquete `com.example.taskflow`, actividad `.MainActivity`
- Captura con `adb exec-out screencap -p` sobre el APK de depuración de este código
- Video H.264 de 10,9 s (1080×2400, 24 fps) de esa misma pantalla en el emulador, no en un teléfono

## Código de origen

La imagen corresponde a la pantalla de bienvenida que ya está en `main` de este repositorio, antes del commit de documentación. `lib/main.dart` no se modificó para la captura ni en esta rama.

| | |
|---|---|
| Repositorio | https://github.com/Mildreth-SC/taskflow |
| Rama para entregar | [`sesion-01`](https://github.com/Mildreth-SC/taskflow/tree/sesion-01) |
| Código de la pantalla | `64378dd4c65d75f4143bf6bcd3442b30b03ea893` en `main` |
| Commit de esa pantalla | `feat: crear pantalla de bienvenida` |
| Video | https://github.com/Mildreth-SC/taskflow/blob/sesion-01/docs/evidencias/sesion-01-ejecucion.mp4 |

## Archivos

`docs/evidencias/sesion-01-bienvenida.png` (1080×2400).

`docs/evidencias/sesion-01-ejecucion.mp4` (10,9 s, H.264, 1080×2400). Es el archivo de video. La entrega de esta sesión es https://github.com/Mildreth-SC/taskflow/tree/sesion-01 y el video https://github.com/Mildreth-SC/taskflow/blob/sesion-01/docs/evidencias/sesion-01-ejecucion.mp4.

En ambos se ve la pantalla fija: **TaskFlow**, «¡Hola, Mildreth Guanoluisa!», «Cada tarea terminada te acerca a tu meta.», «Bienvenido/a a Desarrollo de aplicaciones móviles.» y «Tareas pendientes: 3». El contador no cambia durante el video.
