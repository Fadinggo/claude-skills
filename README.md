# claude-skills

David 自己的 Claude Code skills，每個資料夾是一個 skill。

| Skill | 用途 |
|---|---|
| `work-playbook` | David 的工作守則（所有對話與 Code 模式）：先判斷深度再選模型與強度、拆單與外包專家、計畫與進度、Fable 大方向決策、驗收與回報 |

## 安裝（每台電腦做一次，PowerShell）

```powershell
git clone https://github.com/Fadinggo/claude-skills "$env:USERPROFILE\claude-skills"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\skills\work-playbook" -Target "$env:USERPROFILE\claude-skills\work-playbook"
```

## 更新

```powershell
git -C "$env:USERPROFILE\claude-skills" pull
```

連結（junction）指向這個資料夾，pull 之後 Claude 下次開對話就會用新版本。

## 規則

- 這裡不放任何金鑰、帳號、密碼或交易資料。
- 修改守則後要 commit，並 push 到 GitHub。
