## 2025-03-25 - Whiptail Checklists lack visual cues for keyboard interactions
**Learning:** CLI UI frameworks like whiptail often lack intuitive visual cues for their keyboard interactions. For example, many users don't realize they must press `<Space>` to toggle items in a `--checklist` before pressing `<Enter>`, leading them to accidentally skip all selections.
**Action:** Always include explicit, inline keyboard instructions (like `(Press <Space> to toggle, <Enter> to confirm)`) in the prompt or title of CLI interactive menus that rely on specific keystrokes.
