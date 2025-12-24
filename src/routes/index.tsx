import { Navigate, createBrowserRouter } from "react-router-dom";
import { MAIN_PATH } from "src/constant";

import MainLayout from "src/layouts/MainLayout";

const router = createBrowserRouter([
  {
    path: "/",
    element: <MainLayout />,
    children: [
      {
        path: MAIN_PATH.root,
        element: <Navigate to={`/${MAIN_PATH.browse}`} />,
      },
      {
        path: MAIN_PATH.browse,
        lazy: () => import("src/pages/HomePage"),
      },
      {
        path: MAIN_PATH.genreExplore,
        children: [
          {
            path: ":genreId",
            lazy: () => import("src/pages/GenreExplore"),
          },
        ],
      },
      {
        path: MAIN_PATH.watch,
        lazy: () => import("src/pages/WatchPage"),
      },
    ],
  },
  {
    path: "/login",
    lazy: () => import("src/pages/LoginPage"),
  },
  {
    path: "/register",
    lazy: () => import("src/pages/RegisterPage"),
  },
  {
    path: "/account",
    lazy: () => import("src/pages/AccountPage"),
  },
]);

export default router;
