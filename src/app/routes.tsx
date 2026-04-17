import { createBrowserRouter } from "react-router";
import RootLayout from "./layouts/RootLayout";
import SplashScreen from "./screens/SplashScreen";
import RoleSelectionScreen from "./screens/RoleSelectionScreen";
import OnboardingScreen from "./screens/OnboardingScreen";
import AuthScreen from "./screens/AuthScreen";
import PassengerHome from "./screens/passenger/PassengerHome";
import BusTrackingScreen from "./screens/passenger/BusTrackingScreen";
import RouteSelectionScreen from "./screens/passenger/RouteSelectionScreen";
import AlertsScreen from "./screens/passenger/AlertsScreen";
import DriverDashboard from "./screens/driver/DriverDashboard";
import DriverRouteScreen from "./screens/driver/DriverRouteScreen";
import ProfileScreen from "./screens/shared/ProfileScreen";
import TripHistoryScreen from "./screens/shared/TripHistoryScreen";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: RootLayout,
    children: [
      { index: true, Component: SplashScreen },
      { path: "role-selection", Component: RoleSelectionScreen },
      { path: "onboarding", Component: OnboardingScreen },
      { path: "auth", Component: AuthScreen },

      // Passenger routes
      { path: "passenger/home", Component: PassengerHome },
      { path: "passenger/track/:busId", Component: BusTrackingScreen },
      { path: "passenger/routes", Component: RouteSelectionScreen },
      { path: "passenger/alerts", Component: AlertsScreen },
      { path: "passenger/profile", Component: ProfileScreen },
      { path: "passenger/history", Component: TripHistoryScreen },

      // Driver routes
      { path: "driver/dashboard", Component: DriverDashboard },
      { path: "driver/route", Component: DriverRouteScreen },
      { path: "driver/profile", Component: ProfileScreen },
      { path: "driver/history", Component: TripHistoryScreen },
    ],
  },
]);
