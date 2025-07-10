import { useState, useRef, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Send, Paperclip, Mic } from "lucide-react";

interface ChatInputProps {
  onSendMessage: (message: string) => void;
  disabled?: boolean;
  placeholder?: string;
}

export function ChatInput({
  onSendMessage,
  disabled = false,
  placeholder = "Message Claude...",
}: ChatInputProps) {
  const [message, setMessage] = useState("");
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (message.trim() && !disabled) {
      onSendMessage(message.trim());
      setMessage("");
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  // Auto-resize textarea
  useEffect(() => {
    const textarea = textareaRef.current;
    if (textarea) {
      textarea.style.height = "auto";
      textarea.style.height = `${Math.min(textarea.scrollHeight, 200)}px`;
    }
  }, [message]);

  return (
    <div className="border-t border-border bg-chat-background/95 backdrop-blur supports-[backdrop-filter]:bg-chat-background/60">
      <div className="max-w-4xl mx-auto p-4">
        <form onSubmit={handleSubmit} className="relative">
          <div className="relative flex items-end gap-3 bg-chat-input-background border border-chat-input-border rounded-2xl p-3">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="h-8 w-8 p-0 flex-shrink-0 hover:bg-chat-hover"
            >
              <Paperclip className="h-4 w-4" />
            </Button>

            <Textarea
              ref={textareaRef}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder={placeholder}
              disabled={disabled}
              className="flex-1 min-h-[40px] max-h-[200px] resize-none border-0 bg-transparent px-0 py-2 focus-visible:ring-0 focus-visible:ring-offset-0 text-sm leading-relaxed"
              rows={1}
            />

            <div className="flex items-center gap-2 flex-shrink-0">
              <Button
                type="button"
                variant="ghost"
                size="sm"
                className="h-8 w-8 p-0 hover:bg-chat-hover"
              >
                <Mic className="h-4 w-4" />
              </Button>

              <Button
                type="submit"
                size="sm"
                disabled={!message.trim() || disabled}
                className="h-8 w-8 p-0 bg-chat-message-user hover:bg-chat-message-user/90 text-chat-message-user-foreground"
              >
                <Send className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </form>

        <div className="text-xs text-muted-foreground text-center mt-2">
          Claude can make mistakes. Please double-check responses.
        </div>
      </div>
    </div>
  );
}
