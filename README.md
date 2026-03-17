# Muscle Sensor Video Affectation 


System Architecture
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
                        by projected sense-data threshold

                        Data flow summary:

EMG sensor samples muscle tension at the wrist/forearm
Boron firmware publishes the value to the Particle Cloud over LTE
Processing sketch issues HTTP GET requests to the Particle API, receiving JSON payloads
The sketch reads the result value from the JSON and maps it to a color threshold range
Each Kinect frame is scanned pixel-by-pixel; red channel values above/below the threshold are boosted or suppressed
The modified frame is drawn to the window in real time


Hardware
ComponentPurposeParticle BoronLTE-connected microcontroller; publishes EMG readingsEMG / muscle sensorReads forearm flexion (analog signal)Lithium-ion batteryPowers the Boron wirelessly — fully wearableMicrosoft Kinect v2Captures real-time depth and color video
The Boron publishes sensor readings as a Particle variable, accessible via the REST API at:
GET https://api.particle.io/v1/devices/{DEVICE_ID}/{VARIABLE}
Authorization: Bearer {ACCESS_TOKEN}

<iframe src="https://player.vimeo.com/video/821194204?badge=0&amp;autopause=0&amp;player_id=0&amp;app_id=58479" width="1000" height="755" frameborder="0" allow="autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media" title="Muscle Sense Video Affectation Device"></iframe><br>

Software
Firmware (Particle Boron — firmware/)
The Boron firmware reads an analog pin connected to the EMG sensor and registers the value as a Particle Cloud variable. It samples continuously in loop() and the cloud handles read requests from any authorized client.
cppint sensorValue = 0;

void setup() {
    Particle.variable("emgReading", sensorValue);
}

void loop() {
    sensorValue = analogRead(A0);
    delay(50);
}
Processing Sketch (sketch/)
The main sketch handles two concerns in parallel:
1. API polling (HTTP GET)
javaimport http.requests.*;

GetRequest get = new GetRequest(
  "https://api.particle.io/v1/devices/" + DEVICE_ID + "/emgReading"
);
get.addHeader("Authorization", "Bearer " + ACCESS_TOKEN);
get.send();
JSONObject response = parseJSONObject(get.getContent());
int muscleValue = response.getInt("result");
2. Kinect frame manipulation
The sketch ingests each Kinect color frame, then iterates over its pixels. The muscleValue from the API is mapped to a red threshold: pixels whose red channel exceeds the threshold are amplified; those below are dampened. The threshold is a live, continuously-updated value — so the video reacts in near real-time to what the wearer's arm is doing.
java// Map muscle value (0–4095) to a threshold range
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

Setup & Dependencies
Requirements

Processing 3+ with:

HTTP Requests for Processing library (Sketch → Import Library → Add Library)
Open Kinect for Processing library (Daniel Shiffman)


Particle CLI for firmware flashing
Particle account with a registered Boron device
Microsoft Kinect v2 + USB adapter

Configuration
Create a config.pde file (or edit the constants at the top of the main sketch):
javaString DEVICE_ID   = "your_boron_device_id";
String ACCESS_TOKEN = "your_particle_access_token";
Running

Flash the Boron firmware via Particle CLI:

bash   particle flash --local firmware/muscle_sensor.ino

Connect the Kinect via USB
Open sketch/MuscleVideoAffectation.pde in Processing and press Run


Design Notes & Potential
This device demonstrates that muscle activity can serve as a continuous, analog input channel — not a button press or a gesture, but a proportional signal that maps to any variable in a digital system. Some directions this opens up:

Accessibility interfaces — proportional muscle control for users with limited motor range
Biofeedback visualizations — turning physiological data into observable, real-time output
Wearable performance art — the wearer's body becomes part of the visual composition
Physical therapy — visual feedback on muscle engagement during rehabilitation exercises
Game controllers — fatigue, tension, and recovery as in-game parameters

The hardware is low-cost, fully wireless, and runs on a battery that fits on the forearm — the entire sensing layer is self-contained.

Repository Structure
.
├── firmware/
│   └── muscle_sensor.ino      # Particle Boron firmware
├── sketch/
│   └── MuscleVideoAffectation.pde  # Processing sketch (main)
└── README.md

Built With

Processing — visual programming environment
Particle Boron — LTE IoT microcontroller
Particle Cloud API — device variable REST API
OpenKinect for Processing — Kinect depth/color library
HTTP Requests for Processing — HTTP client library


A wearable prototype exploring the potential of muscle sensing as a real-time creative interface.
Using Particle hardtech (Particle Boron, a bluetooth microcontroller) to receive signal from muscle sense data in order to affect visual representation on Kinect webcam using using C#, integreting JSON GET Requests via Processing, bridging the Particle API. 

Video documentation of live script here: https://vimeo.com/821194204

