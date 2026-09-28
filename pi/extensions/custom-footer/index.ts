import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { execSync } from "child_process";
import { writeFileSync } from "fs";

const USD_TO_EUR = 0.92; // Default rate, can be adjusted

function safeLog(msg: string) {
  try {
    writeFileSync("/tmp/pi-custom-footer.log", `${new Date().toISOString()} ${msg}\n`, { flag: "a" });
  } catch {}
}

interface FooterState {
  changedFiles: number;
  isWorktree: boolean;
  lastUpdated: number;
}

export default function (pi: ExtensionAPI) {
  safeLog("Extension factory executed");

  let sessionStartTimestamp = 0;
  let latestCtx: ExtensionContext | null = null;

  const setupFooter = (ctx: ExtensionContext) => {
    if (!ctx || ctx.mode !== "tui" || !ctx.ui) {
      return false;
    }

    safeLog(`Applying setFooter... Mode: ${ctx.mode}`);
    
    if (sessionStartTimestamp === 0) {
      sessionStartTimestamp = Date.now();
    }

    const state: FooterState = {
      changedFiles: 0,
      isWorktree: false,
      lastUpdated: 0,
    };

    const updateGitStatus = () => {
      try {
        const commonDir = execSync("git rev-parse --git-common-dir", { encoding: "utf8" }).trim();
        const topLevel = execSync("git rev-parse --show-toplevel", { encoding: "utf8" }).trim();
        state.isWorktree = commonDir !== topLevel + "/.git";
        state.changedFiles = parseInt(execSync("git status --porcelain | wc -l", { encoding: "utf8" }).trim()) || 0;
        state.lastUpdated = Date.now();
      } catch (e) {
        // Not a git repo
      }
    };

    updateGitStatus();
    const interval = setInterval(updateGitStatus, 5000);

    ctx.ui.setFooter((tui, theme, footerData) => {
      safeLog("setFooter callback registered");
      const unsubBranch = footerData.onBranchChange(() => {
        updateGitStatus();
        tui.requestRender();
      });

      return {
        dispose: () => {
          safeLog("Footer disposed");
          unsubBranch();
          clearInterval(interval);
        },
        invalidate() {},
        render(width: number): string[] {
          let input = 0, output = 0, costUsd = 0;
          for (const e of ctx.sessionManager.getBranch()) {
            if (e.type === "message" && e.message.role === "assistant") {
              const m = e.message as AssistantMessage;
              input += m.usage.input;
              output += m.usage.output;
              costUsd += m.usage.cost.total;
            }
          }

          const costEur = costUsd * USD_TO_EUR;
          const elapsedMin = (Date.now() - sessionStartTimestamp) / 60000 || 1 / 60;
          const tpm = (input + output) / elapsedMin;

          const fmt = (n: number) => (n < 1000 ? `${Math.round(n)}` : `${(n / 1000).toFixed(1)}k`);
          
          const cwd = ctx.cwd || "unknown";
          const firstLineLeft = cwd;
          
          const provider = ctx.model?.provider || "unknown";
          const modelId = ctx.model?.id || "no-model";
          const modelName = ctx.model?.name || modelId;
          
          const strength = (ctx as any).thinkingLevel || "";
          const strengthStr = strength ? ` • ${strength}` : "";
          const rightLine1 = theme.fg("dim", `(${provider}) ${modelName}${strengthStr}`);
          
          const pad1 = " ".repeat(Math.max(1, width - visibleWidth(firstLineLeft) - visibleWidth(rightLine1)));
          const line1 = truncateToWidth(firstLineLeft + pad1 + rightLine1, width);
          
          const tokensStr = `In:${fmt(input)} Out:${fmt(output)}`;
          const statsStr = `€${costEur.toFixed(3)} | ${fmt(tpm)} tpm`;
          
          const left = theme.fg("dim", `${tokensStr} ${statsStr}`);
          const branch = footerData.getGitBranch() || "no-//branch";
          const branchPrefix = state.isWorktree ? "wt:" : "git:";
          const branchStr = branch !== "no-branch" ? `${branchPrefix}${branch}` : "no-branch";
          const rightLine2 = theme.fg("dim", `${branchStr} | ${state.changedFiles} files`);
          const pad2 = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(rightLine2)));
          const line2 = truncateToWidth(left + pad2 + rightLine2, width);

          return [line1, line2];
        },
      };
    });

    return true;
  };

  // Heartbeat: try to apply the footer to the most recent context every 2 seconds.
  setInterval(() => {
    if (latestCtx) {
      setupFooter(latestCtx);
    }
  }, 2000);

  const eventsToHook = [
    "session_start",
    "before_agent_start",
    "tool_call",
    "message_end",
    "turn_end"
  ];

  eventsToHook.forEach(event => {
    pi.on(event, (_event: unknown, ctx: ExtensionContext) => {
      safeLog(`Event ${event} fired. Mode: ${ctx?.mode}`);
      latestCtx = ctx;
      setupFooter(ctx);
    });
  });

  pi.registerCommand("force-footer", {
    description: "Force apply the custom footer",
    handler: async (_args, ctx) => {
      latestCtx = ctx;
      if (setupFooter(ctx)) {
        ctx.ui.notify("Custom footer applied!", "success");
      } else {
        ctx.ui.notify(`Failed to apply footer. Mode: ${ctx.mode}`, "error");
      }
    }
  });
}
