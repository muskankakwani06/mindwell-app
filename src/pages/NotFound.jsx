import { Link } from "react-router-dom";
export default function NotFound() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center text-center px-4">
      <h1 className="text-6xl font-bold text-muted-foreground/30 mb-2" style={{ fontFamily: "var(--font-heading)" }}>404</h1>
      <p className="text-muted-foreground mb-6">Page not found</p>
      <Link to="/" className="bg-primary text-[hsl(var(--primary-foreground))] px-5 py-2 rounded-lg text-sm hover:opacity-90 transition">Go Home</Link>
    </div>
  );
}
