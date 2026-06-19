# Cambios Realizados

## Resumen

Se implementaron dos funcionalidades principales:

1. **Anuncio por voz de cambios de actividad** — usando `flutter_tts`
2. **Detección de caídas con diálogo de confirmación** — usando `sensors_plus`

---

## 1. Archivos Nuevos

### `lib/services/activity_announcer.dart`
Servicio que anuncia en voz alta los cambios de actividad detectados.

- Usa `FlutterTts` con idioma `es-ES`
- Mensajes según el tipo de actividad:
  - `running` → "Estás corriendo"
  - `walking` → "Cambiaste a caminata"
  - `stationary` → "Te has detenido"
- Inicialización lazy con try-catch (reintenta si falla)
- `onActivityUpdate(ActivityType)` es síncrono (void) — evita Futures perdidos que silencien excepciones
- **Mecanismo de debounce de 2s:** el anuncio solo se dispara si el nuevo tipo de actividad se mantiene estable durante 2 segundos y es diferente del último anunciado. Si durante la espera llega un tipo distinto, el timer se reinicia.
- `_speak()` encapsulado con try-catch y verifica el `bool` de retorno de `speak()`
- Timer callback actualiza `_lastAnnounced` y `_pendingType` sincrónicamente **antes** de llamar `_speak`, eliminando race conditions

### `lib/services/fall_detector.dart`
Servicio que detecta caídas usando el acelerómetro de `sensors_plus`.

- Escucha el stream de acelerómetro cada 100ms
- Calcula la magnitud del vector: `sqrt(x² + y² + z²)`
- **Detección en dos fases:**
  1. Impacto: magnitud > 25 m/s²
  2. Post-caída: tras 2 segundos, magnitud < 11 m/s² (persona inmóvil)
- Dispara `onFallDetected()` cuando se cumplen ambas condiciones

### `lib/widgets/fall_dialog.dart`
Diálogo modal que se muestra al detectar una caída.

- Título: "Alerta de Caída" con ícono de advertencia
- Mensaje inicial: "Hemos detectado una posible caída. ¿Te encuentras bien?"
- **Timeout de 15 segundos:** si no hay respuesta, el texto cambia a:
  "¡Por favor, responde! Hemos detectado una caída y necesitamos confirmar que estás bien."
  (el texto se muestra en rojo)
- Botón verde "Sí, estoy bien" para confirmar y cerrar
- `barrierDismissible: false` — el usuario no puede cerrarlo sin responder

---

## 2. Archivos Modificados

### `pubspec.yaml`
Se agregaron dos dependencias:

```yaml
dependencies:
  ...
  flutter_tts: ^4.0.2
  sensors_plus: ^6.0.0
```

### `lib/features/steps/presentation/widgets/step_counter_widget.dart`
- Se agregaron dos parámetros opcionales al widget:
  - `dataSource` (`AccelerometerDataSource?`) — permite inyectar una instancia compartida desde el padre
  - `onActivityChanged` (`void Function(ActivityType)?`) — notifica cada tipo de actividad recibido (para que el `ActivityAnnouncer` haga el debounce internamente)
- El callback `onActivityChanged` ahora se invoca en **cada evento** del stream, no solo en transiciones (el `ActivityAnnouncer` se encarga del debounce)
- Se eliminó el campo `_lastActivity` (el tracking de cambios ahora lo maneja el `Announcer`)
- Inicialización de `_dataSource` en `initState()` para soportar la inyección

### `lib/main.dart`
- `HomePage` convertido de `StatelessWidget` a `StatefulWidget`
- Se agregó `GlobalKey<NavigatorState> navigatorKey` (top-level) para mostrar diálogos desde servicios
- El `MaterialApp` ahora usa `navigatorKey`
- `_HomePageState` crea y gestiona:
  - `AccelerometerDataSource` compartida (inyectada a `StepCounterWidget`)
  - `ActivityAnnouncer` — recibe el callback `onActivityChanged` y lo deriva a `onActivityUpdate(type)` (con debounce de 2s interno)
  - `FallDetector` — se inicia en `initState()`, detiene en `dispose()`
- Manejador `_onFallDetected()` que muestra el `FallDialog`
- Limpieza adecuada en `dispose()` de todos los servicios

---

## 3. Flujo de Funcionamiento

### Anuncios de Actividad
```
Usuario presiona "Iniciar" en StepCounterWidget
  → startCounting() activa el sensor
  → StepCounterWidget recibe datos del stream (cada ~300ms)
  → onActivityChanged(type) → ActivityAnnouncer.onActivityUpdate(type)
  → Si type == lastAnnounced → se cancela cualquier timer pendiente
  → Si type != lastAnnounced y type != pendingType → se reinicia timer de 5s
  → Si el mismo type persiste 5s sin interrupción → TTS habla en voz alta
  → Si cambia durante la espera → el timer se reinicia con el nuevo tipo
```

### Detección de Caídas
```
FallDetector.start() se ejecuta al entrar a HomePage
  → Escucha acelerómetro continuamente (sensors_plus)
  → Magnitud > 25 m/s² → posible impacto
  → Espera 2 segundos
  → Si magnitud < 11 m/s² → confirma caída
  → Dispara onFallDetected → muestra FallDialog
  → Usuario no responde en 15s → mensaje secundario urgente
  → Usuario presiona "Sí, estoy bien" → diálogo se cierra
```
