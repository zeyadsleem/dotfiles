import { execFileSync } from "node:child_process";

export default {
  id: "workmux-status",

  async setup(ctx: any) {
    try {
      execFileSync("workmux", ["register-agent"], { stdio: "ignore" });
    } catch {
      // Status tracking remains available when registration cannot reach workmux.
    }

    const statusBySession = new Map<string, string>();
    const acceptBusyBySession = new Map<string, boolean>();
    const deletedSessions = new Set<string>();
    let reportedStatus: string | undefined;
    let statusQueue = Promise.resolve();

    function writeStatus(status: string) {
      return (async () => {
        try {
          execFileSync("workmux", ["set-window-status", status], { stdio: "ignore" });
        } catch {
          /* ignored */
        }
      })();
    }

    function queueStatus(status: string) {
      statusQueue = statusQueue.then(
        () => writeStatus(status),
        () => writeStatus(status),
      );
      return statusQueue;
    }

    async function reportAggregateStatus() {
      const statuses = [...statusBySession.values()];
      let status = "done";
      if (statuses.includes("waiting")) status = "waiting";
      else if (statuses.includes("working")) status = "working";

      if (reportedStatus === status) return;
      reportedStatus = status;
      await queueStatus(status);
    }

    async function setStatus(sessionID: string | undefined, status: string) {
      if (!sessionID || deletedSessions.has(sessionID)) return;
      const previous = statusBySession.get(sessionID);
      if (status === "done" && previous === undefined) return;
      if (status === "working" && acceptBusyBySession.get(sessionID) === false) return;
      if (previous === status) return;

      statusBySession.set(sessionID, status);
      if (status === "done") acceptBusyBySession.set(sessionID, false);
      else acceptBusyBySession.set(sessionID, true);

      await reportAggregateStatus();
    }

    const controller = new AbortController();
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          if (event.type === "message.updated" && event.properties?.info?.role === "user") {
            const sessionID = event.properties.info.sessionID;
            if (sessionID) acceptBusyBySession.set(sessionID, true);
          }

          switch (event.type) {
            case "session.status":
              if (event.properties?.status?.type === "busy") {
                await setStatus(event.properties.sessionID, "working");
              }
              if (event.properties?.status?.type === "idle") {
                await setStatus(event.properties.sessionID, "done");
              }
              break;
            case "permission.asked":
            case "question.asked":
              await setStatus(event.properties?.sessionID, "waiting");
              break;
            case "permission.replied":
            case "question.replied":
              await setStatus(event.properties?.sessionID, "working");
              break;
            case "session.idle":
              await setStatus(event.properties?.sessionID, "done");
              break;
            case "session.deleted": {
              const sessionID = event.properties?.info?.id;
              if (!sessionID) break;
              deletedSessions.add(sessionID);
              acceptBusyBySession.delete(sessionID);
              if (statusBySession.delete(sessionID)) {
                await reportAggregateStatus();
              }
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