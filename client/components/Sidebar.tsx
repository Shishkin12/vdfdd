import { useState } from "react";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Plus,
  MessageSquare,
  Settings,
  HelpCircle,
  Menu,
  X,
  MoreHorizontal,
} from "lucide-react";

interface SidebarProps {
  conversations: Array<{
    id: string;
    title: string;
    timestamp: string;
  }>;
  activeConversationId?: string;
  onSelectConversation: (id: string) => void;
  onNewConversation: () => void;
}

export function Sidebar({
  conversations,
  activeConversationId,
  onSelectConversation,
  onNewConversation,
}: SidebarProps) {
  const [isCollapsed, setIsCollapsed] = useState(true);

  return (
    <>
      {/* Mobile backdrop */}
      {!isCollapsed && (
        <div
          className="fixed inset-0 bg-black/50 z-40 md:hidden"
          onClick={() => setIsCollapsed(true)}
        />
      )}

      {/* Sidebar */}
      <div
        className={`fixed left-0 top-0 h-full bg-sidebar border-r border-sidebar-border z-50 transition-transform duration-200 ease-in-out ${
          isCollapsed ? "-translate-x-full md:translate-x-0" : "translate-x-0"
        } w-80 md:w-64`}
      >
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="flex items-center justify-between p-4 border-b border-sidebar-border">
            <h2 className="font-semibold text-sidebar-foreground">Claude</h2>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsCollapsed(!isCollapsed)}
              className="h-8 w-8 p-0 hover:bg-sidebar-accent md:hidden"
            >
              <X className="h-4 w-4" />
            </Button>
          </div>

          {/* New conversation button */}
          <div className="p-3">
            <Button
              onClick={onNewConversation}
              className="w-full justify-start gap-3 bg-sidebar-primary text-sidebar-primary-foreground hover:bg-sidebar-primary/90"
            >
              <Plus className="h-4 w-4 flex-shrink-0" />
              New conversation
            </Button>
          </div>

          {/* Conversations list */}
          <ScrollArea className="flex-1 px-3">
            <div className="space-y-1">
              {conversations.map((conversation) => (
                <Button
                  key={conversation.id}
                  variant="ghost"
                  onClick={() => onSelectConversation(conversation.id)}
                  className={`w-full justify-start gap-3 h-auto p-3 text-left group ${
                    activeConversationId === conversation.id
                      ? "bg-sidebar-accent text-sidebar-accent-foreground"
                      : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
                  }`}
                >
                  <MessageSquare className="h-4 w-4 flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="font-medium truncate">
                      {conversation.title}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      {conversation.timestamp}
                    </div>
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-6 w-6 p-0 opacity-0 group-hover:opacity-100 hover:bg-sidebar-accent"
                    onClick={(e) => {
                      e.stopPropagation();
                      // Handle conversation options
                    }}
                  >
                    <MoreHorizontal className="h-3 w-3" />
                  </Button>
                </Button>
              ))}
            </div>
          </ScrollArea>

          {/* Footer */}
          <div className="border-t border-sidebar-border p-3 space-y-1">
            <Button
              variant="ghost"
              className="w-full justify-start gap-3 text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
            >
              <Settings className="h-4 w-4 flex-shrink-0" />
              Settings
            </Button>
            <Button
              variant="ghost"
              className="w-full justify-start gap-3 text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
            >
              <HelpCircle className="h-4 w-4 flex-shrink-0" />
              Help
            </Button>
          </div>
        </div>
      </div>

      {/* Mobile menu button */}
      {isCollapsed && (
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setIsCollapsed(false)}
          className="fixed top-4 left-4 z-50 md:hidden h-8 w-8 p-0 bg-background border border-border"
        >
          <Menu className="h-4 w-4" />
        </Button>
      )}
    </>
  );
}
