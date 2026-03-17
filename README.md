# Muscle Sensor Video Affectation

> **The body as the controller.** A fully wearable EMG device strapped to the arm uses muscle flexion to manipulate the red color threshold of a real-time Kinect video feed — no buttons, no knobs, just movement.
> Video documentation of live actuation call-response here: https://vimeo.com/821194204

---


<img src="https://anaismorales.com/assets/muscleflex_armdrawing.png" alt="Alt text" width="500" height="400">


## Functionality

This project turns forearm muscle activity into a live video filter. A **Particle Boron** microcontroller reads an EMG (electromyography) sensor mounted at the wrist and forearm. That sensor data travels over LTE to the **Particle Cloud API**, where a **Processing sketch** polls it continuously via HTTP GET. The sketch simultaneously captures a depth-aware video stream from a **Microsoft Kinect** and uses the incoming muscle values to widen or narrow the red color threshold across every frame.

- **Arm flexion inward** (wrist and forearm pulling toward the body) → widens red surface area in the video
- **Arm extension outward** (forearm pulling away) → reduces red surface area
- The body itself mediates every visual result

<img src="https://anaismorales.com/assets/muscleflex1.jpg">

---

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│  WEARABLE DEVICE                                    │
│                                                     │
│  [EMG Sensor] ──────► [Particle Boron (LTE)]        │
│                              │                      │
│                        [Li-ion Battery]             │
└──────────────────────────────┼──────────────────────┘
                               │ publishes sensor data
                               ▼
                     [Particle Cloud API]
                               │ REST / JSON
                               ▼
                      [Processing Sketch]
                       HTTP GET polling
                           │        │
              [Kinect v2]──┘        │
          depth + colour feed       │
                                    ▼
                         [Live Video Output]
                      red threshold controlled
                        by muscle flexion value
```

**Data flow summary:**
1. EMG sensor samples muscle tension at the wrist/forearm
2. Boron firmware publishes the value to the Particle Cloud over LTE
3. Processing sketch issues HTTP GET requests to the Particle API, receiving JSON payloads
4. The sketch reads the `result` value from the JSON and maps it to a color threshold range
5. Each Kinect frame is scanned pixel-by-pixel; red channel values above/below the threshold are boosted or suppressed
6. The modified frame is drawn to the window in real time

---


## Hardware

| Component | Purpose |
|---|---|
| Particle Boron | LTE-connected microcontroller; publishes EMG readings |
| EMG / muscle sensor | Reads forearm flexion (analog signal) |
| Lithium-ion battery | Powers the Boron wirelessly — fully wearable |
| Microsoft Kinect v2 | Captures real-time depth and color video |

The Boron publishes sensor readings as a Particle variable, accessible via the REST API at:

```
GET https://api.particle.io/v1/devices/{DEVICE_ID}/{VARIABLE}
Authorization: Bearer {ACCESS_TOKEN}
```

---

## Software

### Firmware (Particle Boron — `firmware/`)

The Boron firmware reads an analog pin connected to the EMG sensor and registers the value as a Particle Cloud variable. It samples continuously in `loop()` and the cloud handles read requests from any authorized client.

```cpp
int sensorValue = 0;

void setup() {
    Particle.variable("emgReading", sensorValue);
}

void loop() {
    sensorValue = analogRead(A0);
    delay(50);
}
```

### Processing Sketch (`sketch/`)

The main sketch handles two concerns in parallel:

**1. API polling (HTTP GET)**

```java
import http.requests.*;

GetRequest get = new GetRequest(
  "https://api.particle.io/v1/devices/" + DEVICE_ID + "/emgReading"
);
get.addHeader("Authorization", "Bearer " + ACCESS_TOKEN);
get.send();
JSONObject response = parseJSONObject(get.getContent());
int muscleValue = response.getInt("result");
```

**2. Kinect frame manipulation**

The sketch ingests each Kinect color frame, then iterates over its pixels. The `muscleValue` from the API is mapped to a red threshold: pixels whose red channel exceeds the threshold are amplified; those below are dampened. The threshold is a live, continuously-updated value — so the video reacts in near real-time to what the wearer's arm is doing.

```java
// Map muscle value (0–4095) to a threshold range
int redThreshold = (int) map(muscleValue, 0, 4095, 50, 200);

// Per-pixel pass
for (int i = 0; i < videoPixels.length; i++) {
    color c = videoPixels[i];
    int r = (int) red(c);
    int g = (int) green(c);
    int b = (int) blue(c);
    if (r > redThreshold) {
        videoPixels[i] = color(255, g, b);  // boost red
    } else {
        videoPixels[i] = color(r / 2, g, b); // suppress red
    }
}
```

---

## Setup & Dependencies

### Requirements

- [Processing 3+](https://processing.org/) with:
  - `HTTP Requests for Processing` library (`Sketch → Import Library → Add Library`)
  - `Open Kinect for Processing` library (Daniel Shiffman)
- [Particle CLI](https://docs.particle.io/getting-started/developer-tools/cli/) for firmware flashing
- Particle account with a registered Boron device
- Microsoft Kinect v2 + USB adapter

### Configuration

Create a `config.pde` file (or edit the constants at the top of the main sketch):

```java
String DEVICE_ID   = "your_boron_device_id";
String ACCESS_TOKEN = "your_particle_access_token";
```

### Running

1. Flash the Boron firmware via Particle CLI:
   ```bash
   particle flash --local firmware/muscle_sensor.ino
   ```
2. Connect the Kinect via USB
3. Open `sketch/MuscleVideoAffectation.pde` in Processing and press **Run**

---

## Design Notes & Potential

This device demonstrates that **muscle activity can serve as a continuous, analog input channel** — not a button press or a gesture, but a proportional signal that maps to any variable in a digital system. Some directions this opens up:

- **Accessibility interfaces** — proportional muscle control for users with limited motor range
- **Biofeedback visualizations** — turning physiological data into observable, real-time output
- **Wearable performance art** — the wearer's body becomes part of the visual composition
- **Physical therapy** — visual feedback on muscle engagement during rehabilitation exercises
- **Game controllers** — fatigue, tension, and recovery as in-game parameters

The hardware is low-cost, fully wireless, and runs on a battery that fits on the forearm — the entire sensing layer is self-contained.

---

<img src="https://anaismorales.com/assets/muscleflex2.jpg" alt="Alt text" width="500" height="400">


## Repository Structure

```
.
├── firmware/
│   └── muscle_sensor.ino      # Particle Boron firmware
├── sketch/
│   └── MuscleVideoAffectation.pde  # Processing sketch (main)
└── README.md
```

---

## Built With

- [Processing](https://processing.org/) — visual programming environment
- [Particle Boron](https://docs.particle.io/reference/hardware/boron/) — LTE IoT microcontroller
- [Particle Cloud API](https://docs.particle.io/reference/cloud-apis/api/) — device variable REST API
- [OpenKinect for Processing](http://shiffman.net/p5/kinect/) — Kinect depth/color library
- [HTTP Requests for Processing](https://github.com/runemadsen/HTTP-Requests-for-Processing) — HTTP client library

---

*A wearable prototype exploring the potential of muscle sensing as a real-time creative interface.*



A prototype exploring the potential of muscle sensing as a real-time creative interface.
Using Particle hardtech (Particle Boron, a bluetooth microcontroller) to receive signal from muscle sense data in order to affect visual representation on Kinect webcam using using C#, integreting JSON GET Requests via Processing, bridging the Particle API. 
