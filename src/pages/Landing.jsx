import { motion } from "framer-motion";
import { Heart, Shield, Users, Calendar, MessageCircle, Brain, ArrowRight } from "lucide-react";
import { Link } from "react-router-dom";

const fadeUp = { hidden: { opacity: 0, y: 20 }, visible: (i) => ({ opacity: 1, y: 0, transition: { delay: i * 0.1, duration: 0.5 } }) };

const features = [
  { icon: Brain, title: "Mental Assessments", desc: "PHQ-9, GAD-7, and Stress tests to track your wellbeing", gradient: "gradient-card-sage" },
  { icon: Calendar, title: "Easy Scheduling", desc: "Book appointments with licensed therapists effortlessly", gradient: "gradient-card-warm" },
  { icon: MessageCircle, title: "Secure Chat", desc: "Private conversations with your therapist", gradient: "gradient-card-lavender" },
  { icon: Users, title: "Support Groups", desc: "Join communities of people who understand your journey", gradient: "gradient-card-sky" },
  { icon: Shield, title: "Safe & Private", desc: "Your data is stored securely in your own database", gradient: "gradient-card-sage" },
  { icon: Heart, title: "Holistic Care", desc: "Feedback-driven approach to your wellness goals", gradient: "gradient-card-warm" },
];

export default function Landing() {
  return (
    <div>
      <section className="gradient-hero py-24 md:py-36 px-4">
        <div className="container mx-auto text-center max-w-3xl">
          <motion.div initial="hidden" animate="visible" variants={fadeUp} custom={0}>
            <span className="inline-block bg-[hsl(152_30%_92%)] text-[hsl(152_40%_28%)] text-xs font-semibold px-3 py-1 rounded-full mb-6">
              Your mental health matters
            </span>
          </motion.div>
          <motion.h1 variants={fadeUp} custom={1} initial="hidden" animate="visible"
            className="text-4xl md:text-6xl text-foreground leading-tight mb-6" style={{ fontFamily: "var(--font-heading)" }}>
            A safe space for your <span className="text-primary">mental wellness</span>
          </motion.h1>
          <motion.p variants={fadeUp} custom={2} initial="hidden" animate="visible"
            className="text-lg text-muted-foreground mb-8 max-w-xl mx-auto">
            Connect with licensed therapists, join support groups, and take assessments — all in one calm, secure platform.
          </motion.p>
          <motion.div variants={fadeUp} custom={3} initial="hidden" animate="visible" className="flex gap-3 justify-center flex-wrap">
            <Link to="/signup" className="inline-flex items-center gap-2 bg-primary text-[hsl(var(--primary-foreground))] px-6 py-3 rounded-xl font-medium hover:opacity-90 transition">
              Get Started Free <ArrowRight className="w-4 h-4" />
            </Link>
            <Link to="/login" className="px-6 py-3 rounded-xl font-medium border border-border text-foreground hover:bg-[hsl(var(--muted))] transition">
              Sign In
            </Link>
          </motion.div>
        </div>
      </section>

      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center mb-14">
            <h2 className="text-3xl md:text-4xl text-foreground mb-3" style={{ fontFamily: "var(--font-heading)" }}>Everything you need</h2>
            <p className="text-muted-foreground max-w-md mx-auto">Comprehensive tools designed to support your mental health journey.</p>
          </div>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-5xl mx-auto">
            {features.map((f, i) => (
              <motion.div key={f.title} variants={fadeUp} custom={i} initial="hidden" whileInView="visible" viewport={{ once: true }}
                className={`${f.gradient} rounded-2xl p-6 border border-border hover:shadow-lg transition-shadow`}>
                <f.icon className="w-8 h-8 text-primary mb-4" />
                <h3 className="text-lg text-foreground mb-2" style={{ fontFamily: "var(--font-heading)" }}>{f.title}</h3>
                <p className="text-sm text-muted-foreground">{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-20 px-4">
        <div className="container mx-auto max-w-2xl text-center bg-primary rounded-3xl p-12">
          <h2 className="text-3xl text-[hsl(var(--primary-foreground))] mb-4" style={{ fontFamily: "var(--font-heading)" }}>
            Start your healing journey today
          </h2>
          <p className="text-[hsl(var(--primary-foreground))]/80 mb-8">Take the first step towards better mental health.</p>
          <Link to="/signup" className="inline-block bg-[hsl(var(--secondary))] text-[hsl(var(--secondary-foreground))] px-6 py-3 rounded-xl font-medium hover:opacity-90 transition">
            Create Free Account
          </Link>
        </div>
      </section>

      <footer className="border-t border-border py-10 px-4">
        <div className="container mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <Heart className="w-5 h-5 text-primary fill-primary/20" />
            <span style={{ fontFamily: "var(--font-heading)" }} className="text-foreground">MindWell</span>
          </div>
          <p className="text-sm text-muted-foreground">&copy; 2026 MindWell. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}
