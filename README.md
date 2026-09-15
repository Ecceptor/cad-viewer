# Confidential 1:1 Physical-Scale CAD WebXR Viewer

A secure, high-precision WebXR CAD viewer engineered specifically for design review on the **Meta Quest Browser (Quest 2/3)**. Built on Three.js, it operates with strict 1:1 physical dimensions, in-memory zero-upload loading for confidential engineering files, and HTTP Basic Authentication gatekeeping.

---

## Key Features

### 1. Strict 1:1 Physical Scale
- **Exact Native Coordinates**: GLB models retain internal scale `(1, 1, 1)` with zero normalization, distortion, or bounding-box downscaling.
- **Physical Calibration**: 1 CAD unit (meter) in your CAD export = 1 physical meter inside the Meta Quest headset.
- **Dimensional HUD**: Real-time readout of every loaded part’s width, height, and depth in both centimeters and meters.

### 2. In-Memory Zero-Upload (Confidentiality)
- Client-side ingestion via `FileReader.readAsArrayBuffer()`.
- Parsed directly in headset RAM via Three.js `GLTFLoader.parse()`.
- **Zero Network Transmission**: 3D CAD geometries, textures, and metadata never touch any external server or telemetry pipeline.

### 3. Smart Side-by-Side Layout & Floor Snapping
- **Floor Snapping**: Calculates exact bounding box (`THREE.Box3`) and offsets $y \mathrel{-}= \text{box.min.y}$ so the bottom rests flush at $y = 0$ on the studio ground grid.
- **Distribution**:
  - Single model: Snapped to $(x=0, y=0, z=-1.5\text{m})$.
  - Multiple models: Distributed side-by-side along the X-axis with a $0.4\text{m}$ clear gap, centered at $x=0$.
- **One-Click Reset**: "Reset Layout & Snap to Floor" button clears any user rotations or translations and restores side-by-side alignment.

### 4. Meta Quest WebXR Interaction
- **Dual 6DOF Controllers**: Laser pointers for aiming with trigger grab and rotate interaction.
- **Reference Space**: `local-floor` alignment ensures ground height matches the physical room floor.
- **Desktop OrbitControls**: Mouse controls for flat-screen 2D preview before entering VR.

### 5. HTTP Basic Auth Gatekeeping & HTTPS
- Containerized Nginx reverse proxy with `.htpasswd` authentication.
- Automatically enforced HTTPS satisfying the Meta Quest Browser WebXR Device API security context.

---

## Project Structure

```
3DVR_viewer/
├── public/
│   ├── index.html            # WebXR 1:1 CAD application
│   └── style.css             # Dark studio styling & glassmorphic HUD
├── Dockerfile                # Production Nginx container (port 8080)
├── docker-entrypoint.sh      # Injects HTTP Basic Auth credentials
├── nginx.conf                # Nginx server block with auth_basic & MIME types
├── firebase.json             # Firebase Hosting configuration
├── test_local_server.ps1     # Native PowerShell preview server with Basic Auth
├── deploy.ps1                # Automated Cloud Run & Firebase deployment script
└── README.md                 # Documentation
```

---

## Local Testing (Native PowerShell)

You can immediately test the application and HTTP Basic Auth on your local machine:

```powershell
.\test_local_server.ps1 -Username admin -Password CadVR2026! -Port 8080
```

1. Open `http://localhost:8080` in your browser.
2. Enter the username (`admin`) and password (`CadVR2026!`).
3. Drag & drop any `.glb` model or click **Add Product Model (.glb)**.

---

## Cloud Run Deployment

To deploy to Google Cloud Run with custom credentials and managed HTTPS:

```powershell
.\deploy.ps1 -Target cloudrun -Username <YOUR_USER> -Password <YOUR_PASS> -Region us-central1
```

Or deploy directly with the `gcloud` CLI:

```bash
gcloud run deploy cad-webxr-viewer \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars BASIC_AUTH_USER=cad_reviewer,BASIC_AUTH_PASS=YourSecurePassword123!
```

---

## Meta Quest Browser Review Steps

1. In your Meta Quest headset, open the **Meta Quest Browser**.
2. Navigate to your deployed HTTPS URL.
3. Enter your HTTP Basic Auth username and password in the browser prompt.
4. Click **"Add Product Model (.glb)"** and select your confidential CAD files from local Quest storage (or drag & drop via Quest Browser).
5. Click **"ENTER VR"** at the bottom of the screen.
6. Walk around the product at true 1:1 physical scale, use controller triggers to lift or rotate parts, and press **"Reset Layout & Snap to Floor"** anytime.
