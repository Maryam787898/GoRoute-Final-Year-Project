import { Outlet } from "react-router";
import { AppProvider } from "../contexts/AppContext";

export default function RootLayout() {
  return (
    <AppProvider>
      <div className="h-screen w-full overflow-hidden bg-white">
        <Outlet />
      </div>
    </AppProvider>
  );
}
