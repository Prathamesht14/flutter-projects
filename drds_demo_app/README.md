# 🏥 DRDS Demo App – Nearby Clinics & Hospitals Finder

DRDS (Doctor Reach & Discovery System) is a Flutter-based demo application that helps users (patients) discover **nearby clinics and hospitals** using **live location or manual search**, similar to Google Maps — but built entirely using **free and open-source map APIs**.

This project is developed as a **college/demo project** and focuses on real-world use cases like emergency services discovery, OPD availability, and clinic service details.

---

## 🚀 Features

### 📍 Location & Map
- Live location detection (browser/mobile permission-based)
- Manual location search (area, city, landmark)
- Interactive map powered by **OpenStreetMap**
- Auto-centering map based on user location

### 🔍 Search & Discovery
- Search bar with **auto-suggestions**
- Find clinics/hospitals near:
  - Current (live) location
  - Searched place (e.g., *Katraj*, *Hadapsar*)
- Highlight nearby medical facilities on map

### 🏥 Clinic / Hospital Details
- Click on any clinic/hospital marker to view:
  - Available services:
    - OPD
    - Emergency
    - Blood Test
    - General Test
  - Working hours / timings
- Popup bottom sheet for clear visibility

### 💯 Cost
- **100% Free APIs**
- No billing, no credit card, no paid map SDKs

---

## 🧰 Tech Stack

### Frontend
- **Flutter**
- Flutter Web (Chrome)
- Flutter Android (USB / Emulator supported)

### Maps & Location (Free)
- **OpenStreetMap** – map tiles
- **flutter_map** – map rendering
- **Geolocator** – live location access
- **Nominatim (OpenStreetMap)** – place search & geocoding

### Backend (Planned)
- Spring Boot (Java)
- PostgreSQL
- REST APIs for clinics, doctors, bookings

---

## 🗺️ APIs Used (Free & Open)

| Purpose | API |
|------|----|
| Map Tiles | OpenStreetMap |
| Map Rendering | flutter_map |
| Live Location | Geolocator |
| Place Search | Nominatim (OSM) |

> No Google Maps API  
> No API keys required  
> No billing risk  

---

## 📂 Project Structure

