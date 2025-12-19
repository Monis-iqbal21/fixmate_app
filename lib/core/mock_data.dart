class MockData {
  static const user = {
    "name": "Dilawar",
    "role": "client",
    "email": "demo@fixmate.com",
    "city": "Karachi",
  };

  static final categories = [
    {"title": "Plumber", "icon": "🛠️"},
    {"title": "Electrician", "icon": "⚡"},
    {"title": "AC Repair", "icon": "❄️"},
    {"title": "Carpenter", "icon": "🪵"},
  ];

  static final jobs = [
    {
      "id": 17,
      "title": "Kitchen sink leakage",
      "category": "Plumber",
      "budget": 3500,
      "status": "Open",
      "location": "Gulshan, Karachi",
      "time": "Today 6:15 PM",
      "desc": "Sink pipe is leaking. Need urgent fix. Tools required."
    },
    {
      "id": 18,
      "title": "Fan wiring issue",
      "category": "Electrician",
      "budget": 2500,
      "status": "In Progress",
      "location": "Johar, Karachi",
      "time": "Yesterday 11:20 AM",
      "desc": "Ceiling fan wiring loose. Sometimes sparks. Fix safely."
    },
    {
      "id": 19,
      "title": "AC servicing",
      "category": "AC Repair",
      "budget": 5000,
      "status": "Done",
      "location": "DHA, Karachi",
      "time": "Mon 4:40 PM",
      "desc": "AC cooling low. Service + gas check needed."
    },
  ];

  static final inbox = [
    {
      "conversationId": 1,
      "name": "Ali (Worker)",
      "last": "Aap ka job dekha, 30 min me aa sakta hun.",
      "time": "2m",
      "unread": 2
    },
    {
      "conversationId": 2,
      "name": "Sara (Worker)",
      "last": "Budget confirm kar dein please.",
      "time": "1h",
      "unread": 0
    },
  ];

  static final messages = [
    {"me": false, "text": "Assalam o Alaikum, job details?", "time": "6:01"},
    {"me": true, "text": "W/salam. Sink leakage, urgent.", "time": "6:02"},
    {"me": false, "text": "Ok. 30 min me reach kar jaun?", "time": "6:03"},
    {"me": true, "text": "Han please. Tools le aana.", "time": "6:04"},
  ];

  static final notifications = [
    {
      "id": 10,
      "title": "Bid received",
      "body": "Ali placed a bid on your job: Kitchen sink leakage",
      "time": "Just now",
      "read": false
    },
    {
      "id": 11,
      "title": "Job marked done",
      "body": "Your job AC servicing has been marked completed.",
      "time": "Yesterday",
      "read": true
    },
  ];
}
