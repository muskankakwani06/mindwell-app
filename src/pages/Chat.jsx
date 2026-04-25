import { useEffect, useState, useRef, useCallback } from "react";
import { MessageCircle, Send, ArrowLeft } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { Link } from "react-router-dom";

export default function Chat() {
  const { user } = useAuth();
  const [chats, setChats] = useState([]);
  const [activeChat, setActiveChat] = useState(null);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const [loadingChats, setLoadingChats] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [mobileView, setMobileView] = useState("list");
  const bottomRef = useRef(null);
  const inputRef = useRef(null);
  const pollingRef = useRef(null);
  const activeChatRef = useRef(null);
  const isSendingRef = useRef(false);

  useEffect(() => { activeChatRef.current = activeChat; }, [activeChat]);

  const loadChats = useCallback(() => {
    fetch(`/api/chat?userId=${user.userId}`)
      .then((r) => r.json())
      .then((d) => { setChats(Array.isArray(d) ? d : []); setLoadingChats(false); })
      .catch(() => setLoadingChats(false));
  }, [user.userId]);

  useEffect(() => { loadChats(); }, [loadChats]);

  const fetchMessages = useCallback((chatId, silent = false) => {
    if (!silent) setLoadingMessages(true);
    return fetch(`/api/chat/messages/${chatId}`)
      .then((r) => r.json())
      .then((d) => {
        if (activeChatRef.current?.Chat_ID === chatId) {
          setMessages(Array.isArray(d) ? d : []);
        }
        if (!silent) setLoadingMessages(false);
      })
      .catch(() => { if (!silent) setLoadingMessages(false); });
  }, []);

  // Start/stop polling when activeChat changes
  useEffect(() => {
    clearInterval(pollingRef.current);
    if (!activeChat) return;
    fetchMessages(activeChat.Chat_ID);
    pollingRef.current = setInterval(() => {
      if (!isSendingRef.current && activeChatRef.current) {
        fetchMessages(activeChatRef.current.Chat_ID, true);
      }
    }, 3000);
    return () => clearInterval(pollingRef.current);
  }, [activeChat, fetchMessages]);

  // Auto-scroll on new messages
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const openChat = (chat) => {
    setActiveChat(chat);
    setMessages([]);
    setInput("");
    setMobileView("chat");
    setTimeout(() => inputRef.current?.focus(), 100);
  };

  const sendMessage = async () => {
    if (!input.trim() || !activeChat || sending) return;
    const text = input.trim();
    const chatId = activeChat.Chat_ID;

    setInput("");
    setSending(true);
    isSendingRef.current = true;

    // Optimistic message — show immediately as "user" bubble
    const tempId = `temp_${Date.now()}`;
    setMessages((prev) => [
      ...prev,
      { Message_ID: tempId, Message_Text: text, Sender_Type: "user", _pending: true },
    ]);

    try {
      const res = await fetch("/api/chat/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ chatId, messageText: text, senderType: "user" }),
      });

      if (res.ok) {
        // Replace optimistic message with confirmed server data
        const data = await fetch(`/api/chat/messages/${chatId}`).then((r) => r.json());
        if (activeChatRef.current?.Chat_ID === chatId) {
          setMessages(Array.isArray(data) ? data : []);
        }
        loadChats();
      } else {
        const errData = await res.json().catch(() => ({}));
        console.error("Send failed:", errData.error);
        // Keep optimistic message visible but mark as failed
        setMessages((prev) =>
          prev.map((m) =>
            m.Message_ID === tempId ? { ...m, _failed: true, _pending: false } : m
          )
        );
      }
    } catch (err) {
      console.error("Send error:", err);
      setMessages((prev) =>
        prev.map((m) =>
          m.Message_ID === tempId ? { ...m, _failed: true, _pending: false } : m
        )
      );
    }

    setSending(false);
    isSendingRef.current = false;
    inputRef.current?.focus();
  };

  const handleKey = (e) => {
    if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  };

  const getInitials = (name = "") =>
    name.split(" ").filter(Boolean).slice(-2).map((n) => n[0]).join("");

  if (loadingChats) return (
    <div className="container mx-auto py-8 px-4 flex items-center justify-center min-h-[60vh]">
      <div className="text-muted-foreground animate-pulse text-sm">Loading your conversations…</div>
    </div>
  );

  return (
    <div className="container mx-auto py-6 px-4">
      <div className="mb-5">
        <h1 className="text-3xl text-foreground" style={{ fontFamily: "var(--font-heading)" }}>Messages</h1>
        <p className="text-muted-foreground text-sm mt-1">Chat with your therapists</p>
      </div>

      <div
        className="grid lg:grid-cols-3 rounded-3xl border border-border overflow-hidden shadow-sm"
        style={{ height: "calc(100vh - 230px)", minHeight: "520px", background: "hsl(var(--card))" }}
      >
        {/* Chat List */}
        <div className={`border-r border-border flex flex-col ${mobileView === "chat" ? "hidden lg:flex" : "flex"}`}>
          <div className="px-4 py-3.5 border-b border-border bg-muted/30">
            <p className="text-[11px] font-bold text-muted-foreground tracking-widest uppercase">Conversations</p>
          </div>
          <div className="flex-1 overflow-y-auto">
            {chats.length === 0 ? (
              <div className="p-6 text-center mt-6">
                <div className="w-14 h-14 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-3">
                  <MessageCircle className="w-6 h-6 text-primary" />
                </div>
                <p className="text-sm text-muted-foreground mb-2">No conversations yet</p>
                <Link to="/therapists" className="text-xs text-primary hover:underline font-semibold">
                  Book a session to start chatting →
                </Link>
              </div>
            ) : (
              chats.map((c) => (
                <button
                  key={c.Chat_ID}
                  onClick={() => openChat(c)}
                  className={`w-full text-left px-4 py-3.5 border-b border-border/50 flex items-center gap-3 transition-colors ${
                    activeChat?.Chat_ID === c.Chat_ID
                      ? "bg-primary/8 border-l-[3px] border-l-primary"
                      : "hover:bg-muted/40"
                  }`}
                >
                  <div className="w-11 h-11 rounded-full bg-gradient-to-br from-primary/25 to-primary/5 flex items-center justify-center text-primary text-sm font-bold shrink-0 border border-primary/15">
                    {getInitials(c.therapist_name)}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-[14px] font-semibold text-foreground truncate">{c.therapist_name}</p>
                    <p className="text-xs text-muted-foreground truncate mt-0.5">
                      {c.last_message || c.Specialization}
                    </p>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>

        {/* Message Area */}
        <div className={`lg:col-span-2 flex flex-col overflow-hidden ${mobileView === "list" ? "hidden lg:flex" : "flex"}`}>
          {!activeChat ? (
            <div className="flex-1 flex flex-col items-center justify-center text-center p-8">
              <div className="w-16 h-16 rounded-full bg-muted flex items-center justify-center mb-4">
                <MessageCircle className="w-7 h-7 text-muted-foreground" />
              </div>
              <p className="text-sm font-semibold text-foreground mb-1">Select a conversation</p>
              <p className="text-xs text-muted-foreground">Choose a chat from the list to start messaging</p>
            </div>
          ) : (
            <>
              {/* Header */}
              <div className="px-4 py-3 border-b border-border flex items-center gap-3 bg-card/90 backdrop-blur-md">
                <button
                  className="lg:hidden mr-1 p-1.5 rounded-xl hover:bg-muted transition"
                  onClick={() => setMobileView("list")}
                >
                  <ArrowLeft className="w-4 h-4 text-muted-foreground" />
                </button>
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary/25 to-primary/5 flex items-center justify-center text-primary text-sm font-bold border border-primary/15">
                  {getInitials(activeChat.therapist_name)}
                </div>
                <div>
                  <p className="text-[14px] font-semibold text-foreground leading-tight">{activeChat.therapist_name}</p>
                  <p className="text-xs text-muted-foreground">{activeChat.Specialization}</p>
                </div>
              </div>

              {/* Messages */}
              <div
                className="flex-1 overflow-y-auto px-4 py-4 space-y-2"
                style={{ background: "hsl(var(--background))" }}
              >
                {loadingMessages ? (
                  <div className="text-center py-8">
                    <p className="text-xs text-muted-foreground animate-pulse">Loading messages…</p>
                  </div>
                ) : messages.length === 0 ? (
                  <div className="text-center py-10">
                    <p className="text-xs text-muted-foreground">No messages yet. Say hello! 👋</p>
                  </div>
                ) : (
                  messages.map((m) => {
                    const isUser = !m.Sender_Type || m.Sender_Type === "user";
                    return (
                      <div key={m.Message_ID} className={`flex ${isUser ? "justify-end" : "justify-start"}`}>
                        {/* Therapist avatar */}
                        {!isUser && (
                          <div className="w-7 h-7 rounded-full bg-gradient-to-br from-primary/25 to-primary/5 flex items-center justify-center text-primary text-[10px] font-bold border border-primary/15 shrink-0 mr-2 mt-1">
                            {getInitials(activeChat.therapist_name)}
                          </div>
                        )}
                        <div
                          className={`max-w-[72%] px-4 py-2.5 text-[13.5px] leading-relaxed shadow-sm transition-opacity ${
                            isUser
                              ? `rounded-[20px] rounded-br-[6px] ${m._failed ? "bg-red-400 text-white" : m._pending ? "opacity-60 bg-primary text-white" : "bg-primary text-white"}`
                              : "rounded-[20px] rounded-bl-[6px] bg-muted text-foreground border border-border"
                          }`}
                        >
                          {m.Message_Text}
                          {m._failed && (
                            <span className="block text-[10px] mt-1 opacity-80">⚠ Failed to send</span>
                          )}
                        </div>
                      </div>
                    );
                  })
                )}
                <div ref={bottomRef} />
              </div>

              {/* Input */}
              <div className="px-3 py-3 border-t border-border bg-card/90 backdrop-blur-md flex items-end gap-2">
                <textarea
                  ref={inputRef}
                  value={input}
                  onChange={(e) => {
                    setInput(e.target.value);
                    e.target.style.height = "auto";
                    e.target.style.height = Math.min(e.target.scrollHeight, 120) + "px";
                  }}
                  onKeyDown={handleKey}
                  placeholder="Type a message…"
                  rows={1}
                  className="flex-1 resize-none rounded-2xl border border-border bg-background px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-ring overflow-hidden leading-relaxed"
                  style={{ minHeight: "42px", maxHeight: "120px" }}
                />
                <button
                  onClick={sendMessage}
                  disabled={sending || !input.trim()}
                  className="p-2.5 rounded-2xl bg-primary text-white hover:opacity-90 active:scale-95 transition-all disabled:opacity-40 shrink-0"
                >
                  <Send className="w-4 h-4" />
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
