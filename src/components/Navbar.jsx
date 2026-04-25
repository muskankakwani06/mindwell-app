import { Link, useLocation, useNavigate } from "react-router-dom";
import { Heart, Menu, X, LogOut, Github, Linkedin, ChevronDown } from "lucide-react";
import { useState, useRef, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { motion, AnimatePresence } from "framer-motion";

const mainNav = [
  { label: "Dashboard", path: "/dashboard" },
  { label: "Therapists", path: "/therapists" },
  { label: "Appointments", path: "/appointments" },
];

const secondaryNav = [
  { label: "Assessment", path: "/assessment" },
  { label: "Groups", path: "/groups" },
  { label: "Chat", path: "/chat" },
  { label: "Payment", path: "/payment" },
  { label: "Feedback", path: "/feedback" },
];

const GITHUB_URL = "https://github.com/muskankakwani06";
const LINKEDIN_URL = "https://www.linkedin.com/in/muskan-kakwani-528753346/";

export default function Navbar() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const [open, setOpen] = useState(false);
  const [showExplore, setShowExplore] = useState(false);
  const dropdownRef = useRef(null);

  const handleLogout = () => { logout(); navigate("/login"); };

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) setShowExplore(false);
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <nav className="sticky top-0 z-50 bg-[hsl(var(--card))]/80 backdrop-blur-lg border-b border-border">
      <div className="container mx-auto flex items-center justify-between h-16 px-4">
        <Link to={user ? "/dashboard" : "/"} className="flex items-center gap-2">
          <Heart className="w-6 h-6 text-primary fill-primary/20" />
          <span style={{ fontFamily: "var(--font-heading)" }} className="text-xl text-foreground">MindWell</span>
        </Link>

        {user && (
          <div className="hidden md:flex items-center gap-1">
            {mainNav.map((item) => (
              <Link key={item.path} to={item.path}
                className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                  pathname === item.path ? "bg-primary text-[hsl(var(--primary-foreground))]" : "text-muted-foreground hover:text-foreground hover:bg-[hsl(var(--muted))]"
                }`}>{item.label}</Link>
            ))}
            
            {/* Explore Dropdown */}
            <div className="relative" ref={dropdownRef}>
              <button onClick={() => setShowExplore(!showExplore)}
                className={`flex items-center gap-1 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                  secondaryNav.some(n => n.path === pathname) ? "bg-primary/10 text-primary" : "text-muted-foreground hover:text-foreground hover:bg-[hsl(var(--muted))]"
                }`}>
                Explore <ChevronDown className={`w-3.5 h-3.5 transition-transform ${showExplore ? "rotate-180" : ""}`} />
              </button>
              
              <AnimatePresence>
                {showExplore && (
                  <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 10 }}
                    className="absolute top-full left-0 mt-2 w-48 bg-[hsl(var(--card))] border border-border rounded-2xl shadow-xl p-2 z-50">
                    {secondaryNav.map((item) => (
                      <Link key={item.path} to={item.path} onClick={() => setShowExplore(false)}
                        className={`block px-3 py-2 rounded-xl text-sm font-medium transition-colors ${
                          pathname === item.path ? "bg-primary text-[hsl(var(--primary-foreground))]" : "text-muted-foreground hover:bg-[hsl(var(--muted))]"
                        }`}>{item.label}</Link>
                    ))}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>
        )}

        <div className="hidden md:flex items-center gap-4">
          {/* Social Links */}
          <div className="flex items-center gap-2 border-r border-border pr-4 mr-1">
            <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="p-2 rounded-full hover:bg-[hsl(var(--muted))] text-muted-foreground hover:text-foreground transition-colors">
              <Github className="w-5 h-5" />
            </a>
            <a href={LINKEDIN_URL} target="_blank" rel="noopener noreferrer" className="p-2 rounded-full hover:bg-[hsl(var(--muted))] text-muted-foreground hover:text-foreground transition-colors">
              <Linkedin className="w-5 h-5" />
            </a>
          </div>

          {user ? (
            <div className="flex items-center gap-3">
              <span className="text-sm text-muted-foreground">Hi, <b className="text-foreground">{user.name}</b></span>
              <button onClick={handleLogout} className="flex items-center gap-1 px-3 py-2 rounded-lg border border-border text-sm text-muted-foreground hover:bg-[hsl(var(--muted))] transition">
                <LogOut className="w-4 h-4" /> Logout
              </button>
            </div>
          ) : (
            <div className="flex gap-2">
              <Link to="/login" className="px-4 py-2 rounded-lg border border-border text-sm font-medium text-foreground hover:bg-[hsl(var(--muted))] transition">Log in</Link>
              <Link to="/signup" className="px-4 py-2 rounded-lg bg-primary text-[hsl(var(--primary-foreground))] text-sm font-medium hover:opacity-90 transition">Sign up</Link>
            </div>
          )}
        </div>

        <button className="md:hidden" onClick={() => setOpen(!open)}>
          {open ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </div>

      {open && (
        <div className="md:hidden border-t border-border bg-[hsl(var(--card))] p-4 space-y-1">
          {user ? (
            <>
              {[...mainNav, ...secondaryNav].map((item) => (
                <Link key={item.path} to={item.path} onClick={() => setOpen(false)}
                  className={`block px-3 py-2 rounded-lg text-sm font-medium ${
                    pathname === item.path ? "bg-primary text-[hsl(var(--primary-foreground))]" : "text-muted-foreground hover:bg-[hsl(var(--muted))]"
                  }`}>{item.label}</Link>
              ))}
              <div className="flex gap-4 py-2 px-3 border-t border-border mt-2">
                <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="text-muted-foreground hover:text-foreground"><Github className="w-5 h-5" /></a>
                <a href={LINKEDIN_URL} target="_blank" rel="noopener noreferrer" className="text-muted-foreground hover:text-foreground"><Linkedin className="w-5 h-5" /></a>
              </div>
              <button onClick={handleLogout} className="w-full text-left px-3 py-2 rounded-lg text-sm text-muted-foreground hover:bg-[hsl(var(--muted))]">Logout</button>
            </>
          ) : (
            <>
              <Link to="/login" onClick={() => setOpen(false)} className="block px-3 py-2 rounded-lg text-sm text-muted-foreground hover:bg-[hsl(var(--muted))]">Log in</Link>
              <Link to="/signup" onClick={() => setOpen(false)} className="block px-3 py-2 rounded-lg text-sm bg-primary text-[hsl(var(--primary-foreground))]">Sign up</Link>
            </>
          )}
        </div>
      )}
    </nav>
  );
}

