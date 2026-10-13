import { execFileSync } from "node:child_process";
import { basename } from "node:path";

const DONE_TODO_STATUSES = new Set(["completed", "cancelled"]);

export default {
  id: "desktop-notifications",

  async setup(ctx: any) {
    const directory = ctx.location.directory;
    const projectName = basename(directory);
    const working = new Set<string>();
    const waiting = new Set<string>();
    const completed = new Set<string>();
    const finishing = new Set<string>();

    async function notify(sessionID: string, message: string, urgent = false): Promise<void> {
      try {
        const session = await ctx.session.get({ sessionID });
        if (!session || (session.parentID && !urgent)) return;
        const title = `OpenCode · ${projectName}`;
        const body = `${message}\n${session.title}`;
        const urgency = urgent ? "critical" : "normal";
        execFileSync(
          "notify-send",
          [
            "--app-name=OpenCode",
            `--urgency=${urgency}`,
            "--expire-time=8000",
            "--",
            title,
            body,
          ],
          { stdio: "ignore" },
        );
      } catch (error: unknown) {
        console.warn("desktop-notifications: could not send:", String(error));
      }
    }

    async function hasPendingTodos(_sessionID: string): Promise<boolean> {
      // V2 has no session.todo API; behave like "none pending" so we notify on completion.
      return false;
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

    const controller = new AbortController();
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          switch (event.type) {
            case "message.updated": {
              if (event.properties?.info?.role === "user") {
                completed.delete(event.properties.info.sessionID);
              }
              break;
            }
            case "session.status": {
              const { sessionID, status } = event.properties ?? {};
              if (!sessionID) break;
              if (status?.type === "busy" && !completed.has(sessionID)) {
                working.add(sessionID);
              } else if (status?.type === "idle") {
                await finish(sessionID);
              }
              break;
            }
            case "session.idle": {
              await finish(event.properties?.sessionID);
              break;
            }
            case "question.asked": {
              const sessionID = event.properties?.sessionID;
              if (!sessionID) break;
              waiting.add(sessionID);
              await notify(sessionID, "فيه سؤال محتاج ردك", true);
              break;
            }
            case "permission.asked": {
              const sessionID = event.properties?.sessionID;
              if (!sessionID) break;
              waiting.add(sessionID);
              await notify(sessionID, "مطلوب موافقتك على إجراء", true);
              break;
            }
            case "question.replied":
            case "question.rejected":
            case "permission.replied": {
              const sessionID = event.properties?.sessionID;
              if (sessionID) waiting.delete(sessionID);
              break;
            }
            case "session.error": {
              const sessionID = event.properties?.sessionID;
              if (!sessionID) break;
              working.delete(sessionID);
              waiting.delete(sessionID);
              finishing.delete(sessionID);
              completed.add(sessionID);
              if (event.properties?.error?.name !== "MessageAbortedError") {
                await notify(sessionID, "حصل خطأ — راجع الجلسة", true);
              }
              break;
            }
            case "session.deleted": {
              const sessionID = event.properties?.info?.id;
              if (!sessionID) break;
              working.delete(sessionID);
              waiting.delete(sessionID);
              completed.delete(sessionID);
              finishing.delete(sessionID);
              break;
            }
          }
        }
      } catch {
        /* aborts end iteration */
      }
    })();

    return () => controller.abort();
  },
};
