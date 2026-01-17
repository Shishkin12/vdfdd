import express from "express";
import cors from "cors";
import { handleDemo } from "./routes/demo";

export function createServer() {
  const app = express();

  // Middleware
  app.use(cors());
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // ClickOnce MIME types and headers
  app.use("/deploy", (req, res, next) => {
    if (req.path.endsWith(".application")) {
      res.set({
        "Content-Type": "application/x-ms-application",
        "Cache-Control": "no-cache, no-store, must-revalidate",
        Pragma: "no-cache",
        Expires: "0",
      });
    } else if (req.path.endsWith(".exe")) {
      res.set({
        "Content-Type": "application/octet-stream",
        "Content-Disposition": "attachment",
        "Cache-Control": "no-cache, no-store, must-revalidate",
      });
    }
    next();
  });

  // Example API routes
  app.get("/api/ping", (_req, res) => {
    res.json({ message: "Hello from Express server v2!" });
  });

  app.get("/api/demo", handleDemo);

  return app;
}
