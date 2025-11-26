# Flutter Voz a Texto - IBM Watson

Aplicación Flutter que permite grabar notas de voz y convertirlas a texto utilizando el servicio IBM Watson Speech to Text.

## Requisitos Previos

- Flutter SDK instalado (versión 3.0 o superior)
- Dart SDK
- Android Studio o Xcode (según la plataforma objetivo)
- Cuenta de IBM Cloud con acceso a Watson Speech to Text
- Editor de código (VS Code recomendado)

## Paso 1: Crear el Proyecto Flutter

1. Abre una terminal en `c:\laragon\www\`
2. Ejecuta:
   ```bash
   flutter create flutter_voz_texto
   cd flutter_voz_texto
   ```

## Paso 2: Configurar Dependencias

1. Abre `pubspec.yaml` y agrega las siguientes dependencias:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     record: ^5.0.0
     path_provider: ^2.1.0
     permission_handler: ^11.0.0
     http: ^1.1.0
   ```

2. Ejecuta:
   ```bash
   flutter pub get
   ```

## Paso 3: Crear la Estructura del Proyecto

Crea los siguientes archivos y carpetas:

```
lib/
├── main.dart
├── models/
│   └── note.dart
├── screens/
│   ├── home_screen.dart
│   └── recording_screen.dart
└── services/
    ├── watson_service.dart
    └── audio_service.dart
```

## Paso 4: Configurar Permisos

### Android
1. Abre `android/app/src/main/AndroidManifest.xml`
2. Agrega antes de `<application>`:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   ```

### iOS
1. Abre `ios/Runner/Info.plist`
2. Agrega antes de `</dict>`:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>Necesitamos acceso al micrófono para grabar notas de voz.</string>
   <key>UIBackgroundModes</key>
   <array>
     <string>audio</string>
   </array>
   ```

## Paso 5: Implementar el Modelo de Datos

Crea `lib/models/note.dart`:
```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });
}
```

## Paso 6: Configurar IBM Watson

1. Inicia sesión en [IBM Cloud](https://cloud.ibm.com/)
2. Crea un servicio de Speech to Text
3. Obtén tu API Key y Service URL
4. Crea `lib/services/watson_service.dart` y configura:
   ```dart
   class WatsonService {
     static const String apiKey = 'TU_API_KEY';
     static const String serviceUrl = 'TU_SERVICE_URL';
     // ...resto del código
   }
   ```

## Paso 7: Implementar el Servicio de Audio

Crea `lib/services/audio_service.dart` para manejar la grabación de audio:
- Inicializar el grabador
- Iniciar/detener grabación
- Guardar archivo de audio
- Obtener permisos

## Paso 8: Crear las Pantallas

### Home Screen
`lib/screens/home_screen.dart`:
- Lista de notas guardadas
- Botón para nueva grabación
- Opciones para ver/eliminar notas

### Recording Screen
`lib/screens/recording_screen.dart`:
- Interfaz de grabación
- Visualización de forma de onda (opcional)
- Controles de grabación
- Envío a Watson para transcripción

## Paso 9: Configurar el Main

En `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voz a Texto',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
```

## Paso 10: Ejecutar la Aplicación

1. Conecta un dispositivo físico o inicia un emulador
2. Verifica la configuración:
   ```bash
   flutter doctor
   ```
3. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## Características Implementadas

- ✅ Grabación de audio en tiempo real
- ✅ Conversión de voz a texto con IBM Watson
- ✅ Almacenamiento local de notas
- ✅ Interfaz intuitiva y responsive
- ✅ Gestión de permisos de micrófono
- ✅ Manejo de errores y estados de carga

## Solución de Problemas

### Error de permisos
- Verifica que los permisos estén correctamente configurados en AndroidManifest.xml e Info.plist
- Solicita permisos en tiempo de ejecución usando `permission_handler`

### Error de conexión con Watson
- Verifica tu API Key y Service URL
- Comprueba tu conexión a internet
- Revisa los logs de la consola para más detalles

### Error al grabar audio
- Asegúrate de tener permisos de micrófono
- Prueba en un dispositivo físico en lugar de emulador
- Verifica que el paquete `record` esté correctamente instalado

## Próximos Pasos

- Implementar almacenamiento persistente con SQLite
- Agregar soporte para múltiples idiomas
- Implementar edición de notas transcritas
- Agregar exportación de notas a PDF/TXT
- Implementar búsqueda de notas

## Recursos

- [Documentación Flutter](https://flutter.dev/docs)
- [IBM Watson Speech to Text](https://cloud.ibm.com/docs/speech-to-text)
- [Package Record](https://pub.dev/packages/record)
- [Permission Handler](https://pub.dev/packages/permission_handler)