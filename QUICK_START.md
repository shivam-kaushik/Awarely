# 🚀 Quick Start Guide - Awarely Smart Reminders

## Step 1: Add Your OpenAI API Key

1. Get your API key from: https://platform.openai.com/api-keys
2. Open `.env` file in project root
3. Replace `your_openai_api_key_here` with your actual key:
   ```
   OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

## Step 2: Build the App

```powershell
# Already done - packages installed!
# flutter pub get

# Build the app
flutter run
```

## Step 3: Try These Examples

### Example 1: Simple Reminder
**Type**: "Call mom tomorrow at 2 PM"

**What happens**:
- ✅ Time: Tomorrow at 2 PM
- ✅ Category: Family (detected from "mom")
- ✅ Priority: Medium (default)

### Example 2: Recurring with Time Range
**Type**: "Drink water every 2 hours between 9 AM and 6 PM"

**What happens**:
- ✅ Recurring: Every 2 hours
- ✅ Time range: 9 AM - 6 PM
- ✅ Category: Health (detected from "drink water")

### Example 3: High Priority with End Date
**Type**: "High priority: Take medicine every 8 hours on weekdays until December 31"

**What happens**:
- ✅ Priority: High
- ✅ Category: Health
- ✅ Recurring: Every 8 hours
- ✅ Days: Monday-Friday
- ✅ End date: Dec 31

### Example 4: Work Meeting
**Type**: "Team standup every Monday at 10 AM"

**What happens**:
- ✅ Category: Work (detected from "standup")
- ✅ Recurring: Every Monday
- ✅ Time: 10 AM
- ✅ Time-of-day: Morning

## 🎯 What Gets Detected Automatically

### Priority Keywords
- "urgent", "critical", "asap" → **Critical** 🔴
- "important", "high priority" → **High** 🟠
- "low priority" → **Low** 🟢
- Default → **Medium** 🟡

### Category Keywords
- "medicine", "health", "doctor", "exercise" → **Health** 💊
- "meeting", "work", "project", "deadline" → **Work** 💼
- "study", "learn", "exam", "homework" → **Study** 📚
- "buy", "shop", "grocery" → **Shopping** 🛒
- "family", "mom", "dad", "kids" → **Family** 👨‍👩‍👧‍👦
- "personal" → **Personal** 👤
- Default → **Other** 📌

### Time Patterns
- "tomorrow at 3 PM"
- "next Monday at 10 AM"
- "in 2 hours"
- "at 8 PM tonight"

### Recurring Patterns
- "every 2 hours"
- "every day at 9 AM"
- "every Monday and Friday"
- "daily", "weekly", "monthly"

### Time Ranges
- "between 9 AM and 6 PM"
- "during work hours" (9 AM - 6 PM)
- "in the morning" (6 AM - 12 PM)
- "in the evening" (5 PM - 9 PM)

### Specific Days
- "weekdays" → Monday-Friday
- "weekends" → Saturday-Sunday
- "Monday and Friday"
- "on Tuesday"

### End Dates
- "until December 31"
- "for 30 days"
- "until next month"

## 🐛 Fixed Bugs

### ✅ Recurring Reminders Keep Firing After Delete
**FIXED**: Now cancels all 50 alarm occurrences when deleting recurring reminders

### ✅ Toggle Doesn't Disable Recurring Reminders
**FIXED**: Now properly cancels all 50 alarms when toggling off

## 💰 Cost Estimate

Using GPT-3.5-turbo:
- Per reminder parse: ~$0.001
- 100 reminders: ~$0.10
- 1000 reminders: ~$1.00

Very affordable! 💸

## 📱 App Flow

1. Open app
2. Tap **+ Add Reminder**
3. Type naturally: "Urgent: Take medicine every 4 hours"
4. GPT parses automatically (< 2 seconds)
5. Review pre-filled smart dialog
6. Tap **Create**
7. Done! 🎉

## 🔧 Troubleshooting

### "No API key configured"
- Check `.env` file exists
- Verify key starts with `sk-`
- Rebuild app after changing `.env`

### "Network error"
- Check internet connection
- Verify firewall not blocking OpenAI API
- Try again (auto-retries once)

### Notifications not showing
- Go to Settings → Apps → Awarely → Notifications
- Enable all notification channels
- Grant "Exact alarm" permission

### Build fails
- Close all apps
- Restart computer
- Try: `flutter clean && flutter pub get && flutter run`

## 🎉 You're Ready!

Just type what you want naturally, and let AI do the rest! 🚀

---

**Need Help?** Check:
- `GPT_NLU_SETUP.md` - Detailed setup guide
- `IMPLEMENTATION_SUMMARY.md` - Technical details
- Logs in terminal for debugging
