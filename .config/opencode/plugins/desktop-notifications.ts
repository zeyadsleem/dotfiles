import type { Plugin } from "@opencode-ai/plugin";
import type { Event as LegacyEvent } from "@opencode-ai/sdk";
import type { Event } from "@opencode-ai/sdk/v2";
import { basename } from "node:path";

const DONE_TODO_STATUSES = new Set(["completed", "cancelled"]);

/** Desktop alerts only when the user is needed or the whole task is finished. */
export const DesktopNotifications: Plugin = async ({ $, client, directory }) => {
  const projectName = basename(directory);
  const working = new Set<string>();
  const waiting = new Set<string>();
  const completed = new Set<string>();
  const finishing = new Set<string>();

  async function notify(sessionID: string, message: string, urgent = false): Promise<void> {
    try {
      const result = await client.session.get({ path: { id: sessionID } });
      const session = result.data;
      // Native child sessions finish frequently; only alert on parent completion.
      if (!session || (session.parentID && !urgent)) return;
      const title = `OpenCode · ${projectName}`;
      const body = `${message}\n${session.title}`;
      const urgency = urgent ? "critical" : "normal";
      await $`notify-send --app-name=OpenCode --urgency=${urgency} --expire-time=8000 -- ${title} ${body}`.quiet();
    } catch (error: unknown) {
      await client.app.log({
        body: {
          service: "desktop-notifications",
          level: "warn",
          message: `Could not send desktop notification: ${String(error)}`,
        },
      });
    }
  }

  // The todo-reminder plugin resumes the session while todos are pending, so
  // stay quiet until the list is clear and only then announce completion.
  async function hasPendingTodos(sessionID: string): Promise<boolean> {
    try {
      const result = await client.session.todo({ path: { id: sessionID } });
      const todos = Array.isArray(result.data) ? result.data : [];
      return todos.some((todo) => !DONE_TODO_STATUSES.has(todo.status));
    } catch {
      return false;
    }
  }

  async function finish(sessionID: string): Promise<void> {
    if (!working.has(sessionID) || waiting.has(sessionID) || finishing.has(sessionID)) return;
    finishing.add(sessionID);
    try {
      if (await hasPendingTodos(sessionID)) return;
      working.delete(sessionID);
      completed.add(sessionID);
      await notify(sessionID, "خلص خالص — جاهز للمراجعة");
    } finally {
      finishing.delete(sessionID);
    }
  }

  return {
    // The plugin's legacy SDK type omits current question/permission events.
    event: async ({ event }: { event: Event | LegacyEvent }): Promise<void> => {
      switch (event.type) {
        case "message.updated":
          if (event.properties.info.role === "user") {
            completed.delete(event.properties.info.sessionID);
          }
          break;
        case "session.status": {
          const { sessionID, status } = event.properties;
          if (status.type === "busy" && !completed.has(sessionID)) {
            working.add(sessionID);
          } else if (status.type === "idle") {
            await finish(sessionID);
          }
          break;
        }
        case "session.idle":
          await finish(event.properties.sessionID);
          break;
        case "question.asked":
          waiting.add(event.properties.sessionID);
          await notify(event.properties.sessionID, "فيه سؤال محتاج ردك", true);
          break;
        case "permission.asked":
          waiting.add(event.properties.sessionID);
          await notify(event.properties.sessionID, "مطلوب موافقتك على إجراء", true);
          break;
        case "question.replied":
        case "question.rejected":
        case "permission.replied":
          waiting.delete(event.properties.sessionID);
          break;
        case "session.error": {
          const sessionID = event.properties.sessionID;
          if (!sessionID) break;
          working.delete(sessionID);
          waiting.delete(sessionID);
          finishing.delete(sessionID);
          completed.add(sessionID);
          // A user abort is not an error the user needs to be told about.
          if (event.properties.error?.name !== "MessageAbortedError") {
            await notify(sessionID, "حصل خطأ — راجع الجلسة", true);
          }
          break;
        }
        case "session.deleted": {
          const sessionID = event.properties.info.id;
          working.delete(sessionID);
          waiting.delete(sessionID);
          completed.delete(sessionID);
          finishing.delete(sessionID);
          break;
        }
      }
    },
  };
};
