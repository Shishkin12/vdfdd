import { useState, useEffect, useRef } from "react";
import { ChatMessage } from "./ChatMessage";
import { ChatInput } from "./ChatInput";
import { Sidebar } from "./Sidebar";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Button } from "@/components/ui/button";
import { Sun, Moon } from "lucide-react";

interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: string;
}

interface Conversation {
  id: string;
  title: string;
  timestamp: string;
  messages: Message[];
}

export function ChatInterface() {
  const [conversations, setConversations] = useState<Conversation[]>([
    {
      id: "1",
      title: "Welcome conversation",
      timestamp: "Today",
      messages: [
        {
          id: "1",
          role: "assistant",
          content:
            "Hello! I'm Claude, an AI assistant created by Anthropic. I'm here to help you with a wide variety of tasks, from answering questions and helping with analysis to creative writing and problem-solving. How can I assist you today?",
          timestamp: "just now",
        },
      ],
    },
  ]);

  const [activeConversationId, setActiveConversationId] = useState("1");
  const [isTyping, setIsTyping] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const activeConversation = conversations.find(
    (conv) => conv.id === activeConversationId,
  );

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [activeConversation?.messages]);

  useEffect(() => {
    // Apply dark mode class to document
    if (isDarkMode) {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
  }, [isDarkMode]);

  const handleSendMessage = async (content: string) => {
    if (!activeConversation) return;

    const newMessage: Message = {
      id: Date.now().toString(),
      role: "user",
      content,
      timestamp: "just now",
    };

    // Add user message
    setConversations((prev) =>
      prev.map((conv) =>
        conv.id === activeConversationId
          ? { ...conv, messages: [...conv.messages, newMessage] }
          : conv,
      ),
    );

    // Simulate AI response
    setIsTyping(true);
    setTimeout(
      () => {
        const aiResponse: Message = {
          id: (Date.now() + 1).toString(),
          role: "assistant",
          content: getAIResponse(content),
          timestamp: "just now",
        };

        setConversations((prev) =>
          prev.map((conv) =>
            conv.id === activeConversationId
              ? { ...conv, messages: [...conv.messages, aiResponse] }
              : conv,
          ),
        );
        setIsTyping(false);
      },
      1000 + Math.random() * 2000,
    );
  };

  const getAIResponse = (userMessage: string): string => {
    const responses = [
      "That's an interesting question! Let me think about that for a moment. Based on what you've asked, I can provide some insights that might be helpful...",
      "I understand what you're asking about. This is actually a topic I find quite fascinating. Let me break this down for you...",
      "Great question! There are several ways to approach this. Let me share some thoughts and perspectives that might be useful...",
      "I appreciate you bringing this up. It's a complex topic with many dimensions to consider. Here's how I would think about it...",
      "That's a thoughtful inquiry. Let me provide you with a comprehensive response that addresses the key points you've raised...",
    ];
    return responses[Math.floor(Math.random() * responses.length)];
  };

  const handleNewConversation = () => {
    const newConversation: Conversation = {
      id: Date.now().toString(),
      title: "New conversation",
      timestamp: "just now",
      messages: [],
    };
    setConversations((prev) => [newConversation, ...prev]);
    setActiveConversationId(newConversation.id);
  };

  const handleSelectConversation = (id: string) => {
    setActiveConversationId(id);
  };

  return (
    <div className="flex h-screen bg-chat-background">
      {/* Sidebar */}
      <Sidebar
        conversations={conversations}
        activeConversationId={activeConversationId}
        onSelectConversation={handleSelectConversation}
        onNewConversation={handleNewConversation}
      />

      {/* Main chat area */}
      <div className="flex-1 flex flex-col ml-0 md:ml-64">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-border bg-chat-background/95 backdrop-blur supports-[backdrop-filter]:bg-chat-background/60">
          <div className="flex-1" />
          <h1 className="text-lg font-semibold text-foreground">Claude</h1>
          <div className="flex-1 flex justify-end">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsDarkMode(!isDarkMode)}
              className="h-8 w-8 p-0 hover:bg-chat-hover"
            >
              {isDarkMode ? (
                <Sun className="h-4 w-4" />
              ) : (
                <Moon className="h-4 w-4" />
              )}
            </Button>
          </div>
        </div>

        {/* Messages area */}
        <ScrollArea className="flex-1">
          <div className="max-w-4xl mx-auto px-4">
            {activeConversation?.messages.length === 0 ? (
              <div className="h-full flex items-center justify-center">
                <div className="text-center max-w-md">
                  <div className="w-16 h-16 bg-chat-message-assistant rounded-full flex items-center justify-center mx-auto mb-4 border border-border">
                    <span className="text-2xl font-medium text-chat-message-assistant-foreground">
                      A
                    </span>
                  </div>
                  <h2 className="text-xl font-semibold text-foreground mb-2">
                    How can I help you today?
                  </h2>
                  <p className="text-muted-foreground">
                    I'm Claude, an AI assistant. I can help with writing,
                    analysis, math, coding, creative projects, and much more.
                  </p>
                </div>
              </div>
            ) : (
              <div className="py-8 space-y-6">
                {activeConversation?.messages.map((message) => (
                  <ChatMessage
                    key={message.id}
                    role={message.role}
                    content={message.content}
                    timestamp={message.timestamp}
                  />
                ))}

                {isTyping && (
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-full bg-chat-message-assistant border border-border flex items-center justify-center text-sm font-medium text-chat-message-assistant-foreground">
                      A
                    </div>
                    <div className="flex-1">
                      <div className="bg-chat-message-assistant border border-border rounded-2xl px-4 py-3 inline-block">
                        <div className="flex gap-1">
                          <div className="w-2 h-2 bg-muted-foreground rounded-full animate-pulse" />
                          <div className="w-2 h-2 bg-muted-foreground rounded-full animate-pulse delay-75" />
                          <div className="w-2 h-2 bg-muted-foreground rounded-full animate-pulse delay-150" />
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                <div ref={messagesEndRef} />
              </div>
            )}
          </div>
        </ScrollArea>

        {/* Input area */}
        <ChatInput
          onSendMessage={handleSendMessage}
          disabled={isTyping}
          placeholder="Message Claude..."
        />
      </div>
    </div>
  );
}
