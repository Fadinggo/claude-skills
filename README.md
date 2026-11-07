# claude-skills

David's Claude Code skills, with one skill per folder.

| Skill | Purpose |
|---|---|
| `work-playbook` | David's working principles for conversations and Code mode: choosing model and effort, delegation, planning, Fable decisions, acceptance, and reporting. |

## Installation

On a new computer, run these commands in PowerShell:

```powershell
git clone https://github.com/Fadinggo/claude-skills "$env:USERPROFILE\claude-skills"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\claude-skills\install.ps1"
```

Skills update automatically at each logon and every 3 hours thereafter. To disable this, run `Unregister-ScheduledTask ClaudeSkillsSync`.

## Updating

To update manually:

```powershell
git -C "$env:USERPROFILE\claude-skills" pull
```

The junctions point to this repository, so Claude uses the updated skills in the next conversation.

## Rules

- Do not store keys, accounts, passwords, or transaction data here.
- Commit and push changes to the working principles to GitHub.
