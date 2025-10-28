# Awarely - GPT-Powered Smart Reminders Setup Guide

## 🎯 What's New?

Your Awarely app now includes **GPT-powered Natural Language Understanding (NLU)** that can automatically extract ALL reminder details from your text input!

### Features
- ✅ **Automatic time/date extraction** ("tomorrow at 3 PM", "next Monday at 10 AM")
- ✅ **Smart priority detection** ("urgent", "critical", "important" → High/Critical priority)
- ✅ **Category recognition** ("medicine" → Health, "meeting" → Work, "study" → Study)
- ✅ **Recurring pattern parsing** ("every 2 hours", "every Monday and Friday")
- ✅ **End date understanding** ("until December 31", "for 30 days")
- ✅ **Time range extraction** ("between 9 AM and 6 PM", "during work hours")
- ✅ **Specific days** ("on weekdays", "Monday and Friday")
- ✅ **Time-of-day preferences** ("in the morning", "evening reminder")

## 📝 Example Inputs

Try these natural language inputs:

1. **"High priority: Take medicine every 8 hours between 9 AM and 6 PM on weekdays until December 31"**
   - ✅ Priority: High
   - ✅ Category: Health
   - ✅ Recurring: Every 8 hours
   - ✅ Time range: 9 AM - 6 PM
   - ✅ Days: Monday-Friday
   - ✅ End date: Dec 31

2. **"Urgent: Call doctor tomorrow at 3 PM"**
   - ✅ Priority: Critical (urgent)
   - ✅ Category: Health
   - ✅ Date/Time: Tomorrow at 3 PM
   - ✅ One-time reminder

3. **"Remind me to drink water every 2 hours during work hours"**
   - ✅ Priority: Medium
   - ✅ Category: Health
   - ✅ Recurring: Every 2 hours
   - ✅ Time range: 9 AM - 6 PM (work hours)
   - ✅ Days: Weekdays

4. **"Team meeting every Monday at 10 AM"**
   - ✅ Category: Work
   - ✅ Recurring: Every Monday
   - ✅ Time: 10 AM

## 🔧 Setup Instructions

### Step 1: Get Your OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Click **"Create new secret key"**
4. Copy the key (starts with `sk-...`)

### Step 2: Configure the API Key

1. Open the `.env` file in your project root:
   ```
   c:\Users\Public\Documents\Learning\Awarely\.env
   ```

2. Replace `your_openai_api_key_here` with your actual API key:
   ```
   OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

3. Save the file

### Step 3: Build and Run

```powershell
# Get dependencies
flutter pub get

# Build and run
flutter run
```

## 💰 Cost Information

The app uses **GPT-3.5-turbo** model which is:
- ⚡ Fast (< 2 seconds)
- 💵 Very cheap (~$0.001 per reminder parsed)
- 🎯 Accurate for reminder parsing

**Estimated costs:**
- 100 reminders = ~$0.10
- 1,000 reminders = ~$1.00

## 🔄 Fallback Behavior

If the GPT API fails or is not configured, the app automatically falls back to:
1. **Basic regex parser** (limited but functional)
2. **Smart reminder dialog** (manual entry with all options)

You'll see a message in the logs:
```
⚠️ OpenAI API key not configured, falling back to basic parser
```

## 🐛 Fixed Bugs

### ✅ Recurring Reminder Deletion Bug (FIXED)
- **Problem**: Deleted recurring reminders continued to fire notifications
- **Cause**: Only 1 alarm was being cancelled, but recurring reminders create 50 alarms
- **Solution**: Now cancels ALL 50 alarm occurrences when deleting

### ✅ Toggle Recurring Reminders (FIXED)
- **Problem**: Toggling recurring reminders off only cancelled 1 alarm
- **Solution**: Now properly cancels all 50 recurring alarms when toggling off

## 📱 How to Use

1. **Type naturally** in the reminder input field
2. The app will automatically parse your text using GPT
3. A **smart dialog** appears with all fields pre-filled
4. Review and adjust if needed
5. Tap **Create Reminder**

## 🔍 Debugging

Enable debug logs to see parsing results:

```dart
debugPrint('✅ GPT parsed: $gptParsed');
```

You'll see output like:
```
✅ GPT parsed: ParsedReminderData(
  title: Take medicine, 
  priority: High, 
  category: Health,
  isRecurring: true,
  repeatInterval: 8,
  repeatUnit: hours,
  timeRange: 09:00-18:00,
  repeatOnDays: [1,2,3,4,5]
)
```

## 🚀 Next Steps

1. **Add your OpenAI API key** to `.env`
2. **Run the app** and test with natural language inputs
3. **Report any parsing issues** so we can improve the prompts

## 📞 Support

If you encounter any issues:
1. Check that `.env` file has the correct API key
2. Ensure you have internet connection (GPT API requires network)
3. Check logs for error messages
4. Try the fallback smart dialog for manual entry

---

## 🎉 Enjoy Your Smart Reminders!

No more tedious form filling - just type what you want, and let AI do the rest! 🚀
