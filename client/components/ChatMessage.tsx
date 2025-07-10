import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Copy, ThumbsUp, ThumbsDown, RefreshCw } from "lucide-react";

interface ChatMessageProps {
  role: "user" | "assistant";
  content: string;
  timestamp?: string;
}

export function ChatMessage({ role, content, timestamp }: ChatMessageProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const isUser = role === "user";

  return (
    <div
      className={`group relative ${isUser ? "ml-auto max-w-3xl" : "w-full"}`}
    >
      <div
        className={`flex gap-3 ${
          isUser ? "flex-row-reverse" : "flex-row"
        } items-start`}
      >
        {/* Avatar */}
        <div
          className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
            isUser
              ? "bg-chat-message-user text-chat-message-user-foreground"
              : "bg-chat-message-assistant text-chat-message-assistant-foreground border border-border"
          }`}
        >
          {isUser ? "U" : "A"}
        </div>

        {/* Message content */}
        <div
          className={`flex-1 min-w-0 ${isUser ? "text-right" : "text-left"}`}
        >
          <div
            className={`inline-block max-w-full rounded-2xl px-4 py-3 ${
              isUser
                ? "bg-chat-message-user text-chat-message-user-foreground"
                : "bg-chat-message-assistant text-chat-message-assistant-foreground border border-border"
            }`}
          >
            <div className="whitespace-pre-wrap break-words text-sm leading-relaxed">
              {content}
            </div>
          </div>

          {/* Timestamp and actions */}
          <div
            className={`flex items-center gap-2 mt-2 text-xs text-muted-foreground ${
              isUser ? "justify-end" : "justify-start"
            }`}
          >
            {timestamp && <span>{timestamp}</span>}

            {!isUser && (
              <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-6 w-6 p-0 hover:bg-chat-hover"
                  onClick={handleCopy}
                >
                  <Copy className="h-3 w-3" />
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-6 w-6 p-0 hover:bg-chat-hover"
                >
                  <ThumbsUp className="h-3 w-3" />
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-6 w-6 p-0 hover:bg-chat-hover"
                >
                  <ThumbsDown className="h-3 w-3" />
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-6 w-6 p-0 hover:bg-chat-hover"
                >
                  <RefreshCw className="h-3 w-3" />
                </Button>
              </div>
            )}
          </div>
        </div>
      </div>

      {copied && (
        <div className="absolute top-0 right-0 bg-foreground text-background text-xs px-2 py-1 rounded pointer-events-none">
          Copied!
        </div>
      )}
    </div>
  );
}
