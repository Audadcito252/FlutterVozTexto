# Flutter Voz a Texto - IBM Watson

Aplicación Flutter que permite grabar notas de voz y convertirlas a texto utilizando el servicio IBM Watson Speech to Text a través de un backend FastAPI. Las notas se guardan en IBM Cloudant.

## 🏗️ Arquitectura

```
Flutter App ←→ FastAPI Backend ←→ IBM Watson STT
                      ↓
                IBM Cloudant DB
```

## Requisitos Previos

### Frontend (Flutter)
- Flutter SDK instalado (versión 3.0 o superior)
- Dart SDK
- Android Studio o Xcode (según la plataforma objetivo)
- Editor de código (VS Code recomendado)

### Backend (FastAPI)
- Python 3.8 o superior
- pip (gestor de paquetes de Python)
- Cuenta de IBM Cloud con:
  - Servicio Watson Speech to Text
  - Base de datos Cloudant

## 📦 Paso 1: Configurar el Backend FastAPI

### 1.1 Crear el proyecto backend

```bash
# Crear carpeta para el backend
mkdir flutter_voz_texto_backend
cd flutter_voz_texto_backend
```

### 1.2 Crear archivo `requirements.txt`

```txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
python-multipart==0.0.6
ibm-watson==7.0.1
ibm-cloud-sdk-core==3.18.0
cloudant==2.15.0
python-dotenv==1.0.0
```

### 1.3 Instalar dependencias

```bash
pip install -r requirements.txt
```

### 1.4 Crear archivo `.env` con tus credenciales

```env
WATSON_API_KEY=tu_watson_api_key_aquí
WATSON_SERVICE_URL=https://api.us-south.speech-to-text.watson.cloud.ibm.com/instances/xxxxx
CLOUDANT_API_KEY=tu_cloudant_api_key_aquí
CLOUDANT_URL=https://xxxxx.cloudantnosqldb.appdomain.cloud
CLOUDANT_DATABASE=voice_notes
```

### 1.5 Obtener credenciales de IBM Cloud

#### Watson Speech to Text:
1. Ve a [IBM Cloud Console](https://cloud.ibm.com/)
2. Crea un servicio de **Speech to Text**
3. En "Manage" → "Credentials", copia:
   - **API Key** → `WATSON_API_KEY`
   - **URL** → `WATSON_SERVICE_URL`

#### IBM Cloudant:
1. En IBM Cloud, crea un servicio de **Cloudant**
2. En "Service Credentials", crea una credencial nueva
3. Copia:
   - **apikey** → `CLOUDANT_API_KEY`
   - **url** → `CLOUDANT_URL`

### 1.6 Estructura del backend

Crea esta estructura de archivos:

```
flutter_voz_texto_backend/
├── main.py              # API endpoints
├── config.py            # Configuración
├── requirements.txt     # Dependencias
├── .env                 # Variables de entorno
├── models/
│   └── note.py         # Modelos Pydantic
└── services/
    ├── watson_service.py    # Integración con Watson
    └── cloudant_service.py  # Integración con Cloudant
```

### 1.7 Ejecutar el backend

```bash
# Opción 1: Con uvicorn directamente
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Opción 2: Ejecutar el script main.py
python main.py
```

El backend estará disponible en:
- API: `http://localhost:8000`
- Documentación interactiva: `http://localhost:8000/docs`

## 📱 Paso 2: Configurar el Frontend Flutter

### 2.1 Navegar al proyecto Flutter

```bash
cd c:\laragon\www\FlutterVozTexto
```

### 2.2 Instalar dependencias

```bash
flutter pub get
```

### 2.3 Configurar la URL del backend

Abre `lib/services/api_service.dart` y modifica la URL según tu entorno:

```dart
class ApiService {
  // ⚠️ Configura según tu plataforma:
  
  // Para Web
  static const String baseUrl = 'http://localhost:8000';
  
  // Para Android Emulator
  // static const String baseUrl = 'http://10.0.2.2:8000';
  
  // Para iOS Simulator
  // static const String baseUrl = 'http://localhost:8000';
  
  // Para dispositivo físico (reemplaza con tu IP local)
  // static const String baseUrl = 'http://192.168.1.100:8000';
  
  // ...
}
```

### 2.4 Configurar permisos

#### Android
Abre `android/app/src/main/AndroidManifest.xml` y agrega:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### iOS
Abre `ios/Runner/Info.plist` y agrega:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Necesitamos acceso al micrófono para grabar notas de voz.</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

## ▶️ Paso 3: Ejecutar la Aplicación

### 3.1 Verificar que el backend esté corriendo

```bash
# En una terminal, verifica el health check
curl http://localhost:8000/health

# Deberías ver: {"status":"healthy","service":"voice-notes-api"}
```

### 3.2 Ejecutar Flutter

```bash
# Para Web
flutter run -d chrome --web-port=8080

# Para Android
flutter run -d <device_id>

# Para listar dispositivos disponibles
flutter devices
```

## 🧪 Paso 4: Probar la Integración

### 4.1 Probar endpoints del backend

```bash
# Health check
curl http://localhost:8000/health

# Listar notas
curl http://localhost:8000/api/notes

# Ver documentación interactiva
# Abre en el navegador: http://localhost:8000/docs
```

### 4.2 Flujo completo en la app

1. **Grabar audio**: Toca el botón "Nueva nota" y presiona el micrófono
2. **Transcribir**: El audio se envía al backend que usa Watson para transcribir
3. **Guardar**: La nota se guarda automáticamente en Cloudant
4. **Ver notas**: La pantalla principal carga las notas desde Cloudant
5. **Eliminar**: Desliza una nota hacia la izquierda para eliminarla

## 🔧 Características Implementadas

- ✅ Grabación de audio en tiempo real
- ✅ Conversión de voz a texto con IBM Watson
- ✅ Almacenamiento persistente en IBM Cloudant
- ✅ Backend REST API con FastAPI
- ✅ Sincronización automática con la base de datos
- ✅ Eliminación de notas (swipe to delete)
- ✅ Interfaz intuitiva y responsive
- ✅ Gestión de permisos de micrófono
- ✅ Manejo de errores y estados de carga
- ✅ Health check del servidor

## 📋 Endpoints del Backend

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Health check del servidor |
| GET | `/` | Información de la API |
| POST | `/api/transcribe` | Transcribe audio (solo transcripción) |
| POST | `/api/notes` | Crea nota (transcribe + guarda en Cloudant) |
| GET | `/api/notes` | Obtiene todas las notas |
| GET | `/api/notes/{id}` | Obtiene una nota específica |
| DELETE | `/api/notes/{id}` | Elimina una nota |

## 🛠️ Solución de Problemas

### Error: "No se puede conectar al servidor"

1. Verifica que el backend esté corriendo:
   ```bash
   curl http://localhost:8000/health
   ```

2. Si usas emulador Android, usa `http://10.0.2.2:8000`

3. Si usas dispositivo físico:
   - Obtén tu IP local: `ipconfig` (Windows) o `ifconfig` (Mac/Linux)
   - Usa `http://TU_IP:8000` en `api_service.dart`
   - Asegúrate de estar en la misma red WiFi

### Error: "Failed to transcribe"

1. Verifica tus credenciales de Watson en `.env`
2. Comprueba que el servicio Watson esté activo en IBM Cloud
3. Revisa los logs del backend para más detalles

### Error: "Error guardando en Cloudant"

1. Verifica las credenciales de Cloudant en `.env`
2. Asegúrate de que la base de datos exista (se crea automáticamente)
3. Comprueba los permisos de la API key de Cloudant

### Error de permisos de micrófono

- Android: Verifica `AndroidManifest.xml`
- iOS: Verifica `Info.plist`
- Prueba en dispositivo físico en lugar de emulador

### Notas no se cargan

1. Abre la documentación del backend: `http://localhost:8000/docs`
2. Prueba el endpoint `GET /api/notes` manualmente
3. Verifica que haya datos en Cloudant (accede al dashboard de Cloudant)

## 📚 Recursos

- [Documentación Flutter](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [IBM Watson Speech to Text](https://cloud.ibm.com/docs/speech-to-text)
- [IBM Cloudant](https://cloud.ibm.com/docs/Cloudant)
- [Package Record](https://pub.dev/packages/record)
- [Package HTTP](https://pub.dev/packages/http)

## 🚀 Próximos Pasos

- Implementar autenticación de usuarios
- Agregar soporte para múltiples idiomas en Watson
- Implementar edición de notas transcritas
- Agregar exportación de notas a PDF/TXT
- Implementar búsqueda de notas
- Agregar reproducción de audio guardado
- Implementar caché local con SQLite

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.