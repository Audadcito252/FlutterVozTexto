# 🔧 Guía de Configuración Backend - Flutter Voz Texto

## 📍 Configuración de URL según plataforma

### 1. Para Web (Chrome)
```dart
// En lib/services/api_service.dart
static const String baseUrl = 'http://localhost:8000';
```

### 2. Para Android Emulator
```dart
// En lib/services/api_service.dart
static const String baseUrl = 'http://10.0.2.2:8000';
```
> **Nota**: `10.0.2.2` es la IP especial que el emulador Android usa para acceder a `localhost` de tu PC.

### 3. Para iOS Simulator
```dart
// En lib/services/api_service.dart
static const String baseUrl = 'http://localhost:8000';
```

### 4. Para Dispositivo Físico (Android/iOS)

#### Paso 1: Obtener tu IP local

**En Windows:**
```powershell
# En PowerShell
ipconfig

# Busca "IPv4 Address" en la sección de tu adaptador WiFi
# Ejemplo: 192.168.1.100
```

**En Mac/Linux:**
```bash
ifconfig

# Busca "inet" en la sección de tu interfaz WiFi (usualmente en0 o wlan0)
# Ejemplo: 192.168.1.100
```

#### Paso 2: Configurar la URL
```dart
// En lib/services/api_service.dart
static const String baseUrl = 'http://192.168.1.100:8000';
// ⬆️ Reemplaza con tu IP local
```

#### Paso 3: Ejecutar el backend
```bash
# Asegúrate de que el backend esté escuchando en todas las interfaces
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### Paso 4: Verificar conectividad
```bash
# Desde tu dispositivo móvil, abre el navegador y visita:
http://TU_IP:8000/health

# Deberías ver: {"status":"healthy","service":"voice-notes-api"}
```

---

## ⚠️ Checklist antes de ejecutar

### Backend (FastAPI)

- [ ] Variables de entorno configuradas en `.env`:
  - [ ] `WATSON_API_KEY`
  - [ ] `WATSON_SERVICE_URL`
  - [ ] `CLOUDANT_API_KEY`
  - [ ] `CLOUDANT_URL`
  - [ ] `CLOUDANT_DATABASE`

- [ ] Dependencias instaladas:
```bash
pip install -r requirements.txt
```

- [ ] Backend ejecutándose:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

- [ ] Health check funcionando:
```bash
curl http://localhost:8000/health
```

### Frontend (Flutter)

- [ ] URL del backend configurada en `lib/services/api_service.dart`
- [ ] Dependencias instaladas:
```bash
flutter pub get
```

- [ ] Permisos configurados:
  - [ ] Android: `AndroidManifest.xml`
  - [ ] iOS: `Info.plist`

---

## 🧪 Pruebas Rápidas

### 1. Probar Backend con curl

```bash
# Health check
curl http://localhost:8000/health

# Listar notas (debería devolver una lista vacía inicialmente)
curl http://localhost:8000/api/notes

# Ver documentación interactiva
# Abre en navegador: http://localhost:8000/docs
```

### 2. Probar Backend con PowerShell

```powershell
# Health check
Invoke-WebRequest -Uri "http://localhost:8000/health" | Select-Object -Expand Content

# Listar notas
Invoke-WebRequest -Uri "http://localhost:8000/api/notes" | Select-Object -Expand Content
```

### 3. Probar desde la app Flutter

1. Ejecuta la app
2. Toca "Nueva nota"
3. Graba un audio de 3-5 segundos
4. Verifica que aparezca el texto transcrito
5. Guarda la nota
6. Verifica que aparezca en la lista principal

---

## 🚨 Solución de Problemas Comunes

### Error: "No se puede conectar al servidor"

**Causa**: La URL está mal configurada o el backend no está corriendo.

**Solución**:
1. Verifica que el backend esté corriendo:
   ```bash
   curl http://localhost:8000/health
   ```

2. Si usas dispositivo físico, verifica que estés en la misma red WiFi

3. Revisa la URL en `lib/services/api_service.dart`

### Error: "Failed to transcribe"

**Causa**: Credenciales de Watson incorrectas o servicio no disponible.

**Solución**:
1. Verifica las credenciales en `.env`
2. Comprueba que el servicio Watson esté activo en IBM Cloud
3. Revisa los logs del backend con `uvicorn`

### Error: "Error guardando en Cloudant"

**Causa**: Credenciales de Cloudant incorrectas o base de datos no existe.

**Solución**:
1. Verifica las credenciales en `.env`
2. Comprueba que el servicio Cloudant esté activo en IBM Cloud
3. La base de datos se crea automáticamente, pero verifica los permisos

### CORS Error (en Web)

**Causa**: El backend no permite peticiones desde el origen de Flutter web.

**Solución**: Verifica que tu `main.py` tenga configurado CORS:
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especifica los orígenes permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 📊 Logs útiles

### Backend logs
Los verás automáticamente en la terminal donde ejecutaste `uvicorn`.

### Flutter logs
```bash
# Ver logs en tiempo real
flutter logs

# Ver logs específicos de HTTP
flutter logs | grep -i "http"
```

---

## 🔐 Seguridad

### Para Desarrollo
- Usa `allow_origins=["*"]` en CORS
- Backend en `0.0.0.0:8000`

### Para Producción
- Especifica los orígenes permitidos en CORS
- Usa HTTPS
- Implementa autenticación JWT
- Usa variables de entorno seguras
- No expongas credenciales en el código

---

## 📞 Información Adicional

Si necesitas ayuda adicional:
1. Revisa la documentación completa en `README.md`
2. Consulta los logs del backend y Flutter
3. Verifica la documentación interactiva del backend: `http://localhost:8000/docs`
