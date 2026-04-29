# Requirements Document

## Introduction

GoRoute is an AI-based smart public transport tracker for Pakistan built with Flutter and Firebase. Currently, the app estimates bus arrival times using a two-tier system: Google Maps Directions API (when a key is configured) and a Haversine straight-line formula fallback. Both approaches are static — they do not learn from historical travel patterns, driver behaviour, or local traffic conditions.

This feature replaces the formula-based ETA calculation with a machine learning prediction system. A Python ML backend trains and serves models that incorporate live GPS data, historical route data, driver speed behaviour, time-of-day patterns, and peak-hour traffic. The Flutter app's `ETAService` is upgraded to call the new REST API, with the existing Haversine formula retained as a graceful fallback. The result is a more accurate, adaptive ETA that improves over time as more trip data is collected.

---

## Glossary

- **ETA_Service**: The Flutter service class (`eta_service.dart`) responsible for computing and returning estimated arrival times to the UI.
- **ML_Backend**: The Python-based FastAPI application that hosts trained ML models and exposes a REST prediction endpoint.
- **Data_Pipeline**: The Python module responsible for extracting raw GPS logs from Firestore, cleaning them, engineering features, and producing a labelled training dataset.
- **Prediction_Model**: The trained machine learning model (one of: Linear Regression, Random Forest, XGBoost, Gradient Boosting, or LSTM) selected for production deployment based on evaluation metrics.
- **Feature_Vector**: The structured set of numerical inputs passed to the Prediction_Model at inference time.
- **Trip_Log**: A Firestore document recording a completed bus trip, including timestamped GPS snapshots, route ID, driver ID, and actual arrival time.
- **Live_Location**: A Firestore document in the `live_locations` collection updated in real time by the driver app, containing `lat`, `lng`, `speed`, `routeId`, `driverName`, and `updatedAt`.
- **Route**: A Firestore document in the `routes` collection containing `from`, `to`, `driverId`, `driverName`, `routeStatus`, and `estimatedTime`.
- **Confidence_Score**: A normalised value between 0.0 and 1.0 indicating the ML_Backend's certainty in a given ETA prediction.
- **Peak_Hour**: Time windows 07:00–09:30 and 17:00–20:00 local time on weekdays, representing high-traffic periods in Pakistani urban areas.
- **MAE**: Mean Absolute Error — average absolute difference between predicted and actual ETA in minutes.
- **RMSE**: Root Mean Squared Error — square root of the average squared prediction error in minutes.
- **R2_Score**: Coefficient of determination measuring the proportion of variance in actual ETAs explained by the model.
- **Haversine_Fallback**: The existing straight-line distance ÷ speed formula in `ETAService.calculateETA()`, retained as a fallback when the ML_Backend is unreachable.
- **GPS_Snapshot**: A single timestamped record of a bus's latitude, longitude, and speed captured during an active trip.

---

## Requirements

### Requirement 1: Data Collection and Trip Logging

**User Story:** As a data engineer, I want the system to automatically record completed bus trips to Firestore, so that historical travel data is available for training the Prediction_Model.

#### Acceptance Criteria

1. WHEN a driver activates a route in the GoRoute app, THE Data_Pipeline SHALL begin recording GPS_Snapshots to a `trip_logs` Firestore collection at intervals no greater than 10 seconds.
2. WHEN a driver deactivates a route, THE Data_Pipeline SHALL write a Trip_Log document containing: `routeId`, `driverId`, `startTime`, `endTime`, `actualDurationMinutes`, `snapshotCount`, and an array of GPS_Snapshots.
3. THE Data_Pipeline SHALL record each GPS_Snapshot with the fields: `lat`, `lng`, `speed`, `timestamp`, `distanceRemainingKm`, and `segmentIndex`.
4. IF a GPS_Snapshot contains a `speed` value less than 0 or greater than 200 km/h, THEN THE Data_Pipeline SHALL discard that snapshot and log a warning.
5. IF a GPS_Snapshot is received more than 30 seconds after the previous snapshot, THEN THE Data_Pipeline SHALL mark the gap with a `dataGap: true` flag on the subsequent snapshot.
6. THE Data_Pipeline SHALL store trip logs in Firestore under the path `trip_logs/{routeId}/{tripId}` to enable efficient per-route querying.

---

### Requirement 2: Feature Engineering

**User Story:** As a data scientist, I want raw GPS and trip data transformed into a structured Feature_Vector, so that the Prediction_Model receives consistent, meaningful inputs.

#### Acceptance Criteria

1. THE Data_Pipeline SHALL compute the following features for each training sample: `distance_remaining_km`, `current_speed_kmh`, `avg_speed_last_5min_kmh`, `hour_of_day` (0–23), `day_of_week` (0–6), `is_peak_hour` (binary), `stop_count_remaining`, `historical_avg_duration_min`, `historical_delay_ratio`, and `segment_index`.
2. WHEN `avg_speed_last_5min_kmh` cannot be computed due to insufficient GPS_Snapshots, THE Data_Pipeline SHALL substitute the value of `current_speed_kmh`.
3. WHEN `historical_avg_duration_min` for a route has fewer than 5 completed Trip_Logs, THE Data_Pipeline SHALL substitute the value derived from the Haversine_Fallback calculation for that route.
4. THE Data_Pipeline SHALL encode `hour_of_day` and `day_of_week` using sine-cosine cyclical encoding to preserve temporal continuity.
5. THE Data_Pipeline SHALL normalise all continuous features using min-max scaling fitted on the training set, and SHALL persist the scaler parameters to a file for use during inference.
6. IF any feature value is missing after all substitution rules are applied, THEN THE Data_Pipeline SHALL impute the missing value with the median of that feature computed from the training set.

---

### Requirement 3: Dataset Labelling and Splitting

**User Story:** As a data scientist, I want a labelled dataset with a proper train/test split, so that model training and evaluation are reproducible and unbiased.

#### Acceptance Criteria

1. THE Data_Pipeline SHALL label each training sample with `actual_eta_minutes`, computed as the difference in minutes between the GPS_Snapshot timestamp and the trip's `endTime`.
2. THE Data_Pipeline SHALL remove samples where `actual_eta_minutes` is less than 0 or greater than 180 minutes as outliers.
3. THE Data_Pipeline SHALL split the dataset into 80% training and 20% test sets using a time-based split, where the most recent 20% of trips by `startTime` form the test set.
4. THE Data_Pipeline SHALL export the processed dataset as CSV files: `train_features.csv`, `train_labels.csv`, `test_features.csv`, and `test_labels.csv`.
5. THE Data_Pipeline SHALL log the total sample count, training sample count, test sample count, and feature column names to a `pipeline_report.json` file upon completion.

---

### Requirement 4: Model Training and Comparison

**User Story:** As a data scientist, I want to train and compare multiple ML models on the same dataset, so that the best-performing model can be selected for production deployment.

#### Acceptance Criteria

1. THE Data_Pipeline SHALL train the following five model types on the training set: Linear Regression, Random Forest Regressor, XGBoost Regressor, Gradient Boosting Regressor, and LSTM Neural Network.
2. WHEN training the LSTM Neural Network, THE Data_Pipeline SHALL reshape input data into sequences of 10 consecutive GPS_Snapshots per trip segment to capture temporal patterns.
3. THE Data_Pipeline SHALL evaluate each trained model on the test set and record: `MAE`, `RMSE`, `R2_Score`, and `accuracy_within_2min_percent` (percentage of predictions within ±2 minutes of actual ETA).
4. THE Data_Pipeline SHALL save all evaluation results to a `model_comparison.json` file containing one entry per model with its metrics.
5. THE Data_Pipeline SHALL serialise each trained model to disk: scikit-learn models as `.pkl` files using joblib, and the LSTM model as a `.h5` file using TensorFlow's save format.
6. WHEN all models are evaluated, THE Data_Pipeline SHALL identify the model with the lowest MAE on the test set and record it as the `selected_model` in `model_comparison.json`.

---

### Requirement 5: ML Backend API

**User Story:** As a Flutter developer, I want a REST API that accepts live bus data and returns an ETA prediction, so that the GoRoute app can display ML-powered arrival times to passengers.

#### Acceptance Criteria

1. THE ML_Backend SHALL expose a `POST /predict_eta` endpoint that accepts a JSON body with the fields: `current_lat` (float), `current_lng` (float), `destination_lat` (float), `destination_lng` (float), `speed` (float), `route_id` (string), and `timestamp` (ISO 8601 string).
2. WHEN a valid request is received, THE ML_Backend SHALL return a JSON response containing: `predicted_eta_minutes` (integer), `confidence_score` (float, 0.0–1.0), `model_used` (string), and `fallback_used` (boolean).
3. THE ML_Backend SHALL load the selected Prediction_Model and scaler parameters from disk at startup and SHALL keep them in memory for the lifetime of the process.
4. WHEN the `route_id` in the request does not match any route in the training data, THE ML_Backend SHALL compute the Feature_Vector using available inputs, set `confidence_score` to a value below 0.5, and proceed with prediction.
5. IF the Prediction_Model raises an exception during inference, THEN THE ML_Backend SHALL return a response with `fallback_used: true` and `predicted_eta_minutes` computed using the Haversine formula: `(distance_km / 30.0) * 60` rounded to the nearest integer.
6. THE ML_Backend SHALL respond to all requests within 500 milliseconds under normal operating conditions.
7. THE ML_Backend SHALL expose a `GET /health` endpoint that returns HTTP 200 with `{"status": "ok"}` when the service is running and the model is loaded.
8. IF the request body is missing any required field, THEN THE ML_Backend SHALL return HTTP 422 with a JSON error body describing the missing fields.

---

### Requirement 6: Flutter Integration

**User Story:** As a passenger, I want the GoRoute app to display ML-predicted arrival times, so that I receive more accurate bus ETAs than the current formula provides.

#### Acceptance Criteria

1. THE ETA_Service SHALL add a method `calculateETAFromML()` that sends a `POST /predict_eta` request to the ML_Backend and returns the `predicted_eta_minutes` value as an integer.
2. WHEN the ML_Backend returns a successful response, THE ETA_Service SHALL update the existing `calculateETASmart()` method to use `calculateETAFromML()` as the primary ETA source, ahead of the Google Directions API tier.
3. IF `calculateETAFromML()` throws an exception or the ML_Backend returns HTTP status other than 200, THEN THE ETA_Service SHALL fall through to the existing Google Directions API tier and then to the Haversine_Fallback without surfacing an error to the UI.
4. THE ETA_Service SHALL apply a 5-second timeout to all HTTP requests sent to the ML_Backend.
5. WHERE the ML_Backend `confidence_score` is below 0.4, THE ETA_Service SHALL append the label "(est.)" to the formatted ETA string returned by `formatEtaMinutes()`.
6. THE ETA_Service SHALL accept the ML_Backend base URL as a configurable constant so that the endpoint can be changed without modifying business logic.
7. WHEN the ML_Backend returns `fallback_used: true`, THE ETA_Service SHALL log a debug message indicating that the ML fallback was used.

---

### Requirement 7: Dynamic ETA Recalculation

**User Story:** As a passenger, I want the displayed ETA to update automatically as the bus moves, so that I always see a current arrival estimate.

#### Acceptance Criteria

1. WHEN the `BusTrackingScreen` receives an updated `Live_Location` from Firestore, THE ETA_Service SHALL recalculate the ETA using the new GPS coordinates and speed.
2. THE ETA_Service SHALL debounce ETA recalculation requests so that no more than one ML_Backend call is made per 15-second window per active tracking session.
3. WHEN the distance between the bus and the passenger drops below 0.1 km, THE ETA_Service SHALL return 0 minutes without calling the ML_Backend.
4. THE ETA_Service SHALL cache the most recent successful ETA prediction and SHALL return the cached value if a new ML_Backend call fails within the same 60-second window.

---

### Requirement 8: Model Serialisation and Round-Trip Integrity

**User Story:** As a data scientist, I want to verify that saved models produce identical predictions when reloaded, so that deployment does not introduce silent prediction errors.

#### Acceptance Criteria

1. THE Data_Pipeline SHALL verify that for every trained scikit-learn model, serialising the model to disk and deserialising it produces predictions identical to the in-memory model on a held-out validation set of 50 samples.
2. THE Data_Pipeline SHALL verify that the LSTM model saved as `.h5` and reloaded produces predictions within a tolerance of 0.001 minutes of the in-memory model on the same 50-sample validation set.
3. FOR ALL Feature_Vectors in the validation set, the round-trip prediction (train → save → load → predict) SHALL produce the same `predicted_eta_minutes` as the original in-memory prediction.
4. IF any round-trip verification fails, THEN THE Data_Pipeline SHALL raise an error and SHALL NOT mark the model as the `selected_model`.

---

### Requirement 9: Evaluation and Accuracy Reporting

**User Story:** As a project evaluator, I want a clear model performance report, so that I can assess whether the ML system outperforms the existing formula-based ETA.

#### Acceptance Criteria

1. THE Data_Pipeline SHALL compute a baseline MAE for the Haversine_Fallback on the test set and include it in `model_comparison.json` as the `baseline` entry.
2. THE Data_Pipeline SHALL compute a baseline MAE for the Google Directions API estimate on the test set where historical data includes road-distance values, and include it as the `google_directions_baseline` entry.
3. THE Prediction_Model selected for production SHALL achieve an MAE of 3 minutes or less on the test set, or the Data_Pipeline SHALL log a warning that no model meets the production accuracy threshold.
4. THE Data_Pipeline SHALL generate a `training_report.md` file containing: dataset summary, feature importance rankings (for tree-based models), model comparison table, selected model name, and a conclusion on whether the ML system outperforms the Haversine_Fallback.
5. WHEN `accuracy_within_2min_percent` for the selected model is below 60%, THE Data_Pipeline SHALL log a warning recommending collection of additional Trip_Logs before production deployment.

---

### Requirement 10: Deployment and Environment Configuration

**User Story:** As a developer, I want the ML_Backend to be deployable with a single command and configurable via environment variables, so that it can be run locally for development and on a server for production.

#### Acceptance Criteria

1. THE ML_Backend SHALL be launchable with the command `uvicorn main:app --host 0.0.0.0 --port 8000` from the project root directory.
2. THE ML_Backend SHALL read the following configuration from environment variables: `MODEL_PATH` (path to the selected model file), `SCALER_PATH` (path to the scaler file), `FIREBASE_CREDENTIALS_PATH` (path to the Firebase service account JSON), and `PORT` (default 8000).
3. THE ML_Backend SHALL include a `requirements.txt` file listing all Python dependencies with pinned versions.
4. THE ML_Backend SHALL include a `README.md` file with setup instructions, environment variable descriptions, and example `curl` commands for the `/predict_eta` and `/health` endpoints.
5. WHERE `FIREBASE_CREDENTIALS_PATH` is set, THE ML_Backend SHALL initialise a Firebase Admin SDK connection to enable direct Firestore queries for route history enrichment.
6. IF `FIREBASE_CREDENTIALS_PATH` is not set, THEN THE ML_Backend SHALL operate in offline mode, computing predictions solely from the fields provided in the request body.
