# Wetter-App mit Flutter & OpenWeatherMap

Eine elegante Wetter-App im Wall Street Journal-Design-Stil, entwickelt mit Flutter und OpenWeatherMap API.

## 📱 Features

- **Aktuelles Wetter**: Temperatur, Beschreibung, Luftfeuchtigkeit, Windgeschwindigkeit
- **Stündliche Vorhersage**: Wettervorhersage für die nächsten 24 Stunden
- **7-Tage-Vorhersage**: Wochenübersicht mit Min/Max-Temperaturen  
- **Städtesuche**: Weltweite Städtesuche mit Geocoding API
- **Elegant Design**: Minimalistisches WSJ-inspiriertes Dark-Theme
- **Responsive UI**: Optimiert für iOS und macOS

## 🏗️ Projektstruktur

```
lib/
├── main.dart                 # App-Entry-Point
├── models/
│   └── weather.dart          # Wetter-Datenmodelle
├── screens/
│   └── home_screen.dart      # Hauptbildschirm
└── widgets/
    ├── hourly_weather_card.dart    # Stündliche Vorhersage Widget
    ├── daily_weather_card.dart     # Tägliche Vorhersage Widget
    └── search_city_dialog.dart     # Suchfeld-Dialog Widget
```


## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  intl: ^0.19.0
```

## 🌐 API-Verwendung

Die App verwendet die **kostenlosen** OpenWeatherMap APIs:

### Current Weather API
```
GET https://api.openweathermap.org/data/2.5/weather
```
- Liefert aktuelle Wetterdaten für eine Stadt
- Parameter: `lat`, `lon`, `units=metric`, `lang=de`, `appid`
- Zeigt: Temperatur, Beschreibung, Icon, Luftfeuchtigkeit, Windgeschwindigkeit

### 5 Day Forecast API
```
GET https://api.openweathermap.org/data/2.5/forecast
```
- Liefert 5-Tage-Vorhersage in 3-Stunden-Intervallen
- Wird für stündliche und tägliche Vorhersagen verwendet

### Geocoding API
```
GET https://api.openweathermap.org/geo/1.0/direct
```
- Konvertiert Städtenamen in GPS-Koordinaten
- Ermöglicht weltweite Städtesuche


## 🔧 Technische Details

### State Management
- StatefulWidget für Zustandsverwaltung
- setState für UI-Updates nach API-Calls
- Separate Controller für TextField

### Error Handling
- Try-Catch für API-Fehler
- Benutzerfreundliche Fehlermeldungen
- Ladestatusindikatoren (CircularProgressIndicator)
- Statusvariablen: `isLoading`, `hasError`

### Datenverarbeitung
- JSON-Parsing der API-Responses
- Umwandlung zu typsicheren Dart-Modellen
- Aggregation von 3h-Intervall-Daten zu Tages-Vorhersagen
- Factory Constructors für Modell-Erstellung

### Code-Struktur
- **models/weather.dart**: Datenmodelle (Weather, HourlyWeather, DailyWeather)
- **screens/home_screen.dart**: Hauptlogik und State Management
- **widgets/**: Wiederverwendbare UI-Komponenten
  - HourlyWeatherCard
  - DailyWeatherCard
  - SearchCityDialog



## 👨‍💻 Entwickler

Entwickelt von Gabriel im Rahmen des Ubiquitous Computing Kurses.

## 📄 Lizenz

Dieses Projekt wurde für Bildungszwecke erstellt.

---

**API-Quelle**: [OpenWeatherMap](https://openweathermap.org/)  
**Framework**: [Flutter](https://flutter.dev/)  
**Datum**: Januar 2026
