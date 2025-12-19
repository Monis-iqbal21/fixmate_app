class DummyData {
  static final user = {
    "name": "Lycan User",
    "role": "client",
    "city": "Karachi",
    "rating": 4.8,
  };

  static final categories = [
    {"title": "Plumber", "icon": "🚰"},
    {"title": "Electrician", "icon": "💡"},
    {"title": "AC Repair", "icon": "❄️"},
    {"title": "Carpenter", "icon": "🪚"},
    {"title": "Painter", "icon": "🎨"},
    {"title": "Cleaning", "icon": "🧹"},
  ];

  static final jobs = [
    {
      "id": 101,
      "title": "Bathroom pipe leakage",
      "category": "Plumber",
      "budget": 3500,
      "status": "Open",
      "date": "Today",
      "location": "Gulshan, Karachi",
      "bids": 6,
    },
    {
      "id": 102,
      "title": "Install ceiling fan",
      "category": "Electrician",
      "budget": 2000,
      "status": "In Progress",
      "date": "Yesterday",
      "location": "Johar, Karachi",
      "bids": 3,
    },
    {
      "id": 103,
      "title": "AC gas refill",
      "category": "AC Repair",
      "budget": 5500,
      "status": "Completed",
      "date": "2 days ago",
      "location": "DHA, Karachi",
      "bids": 9,
    },
  ];

  static final inbox = [
    {
      "convId": 1,
      "name": "Ali Electrician",
      "last": "Boss fan ki wiring done, check kar lo ✅",
      "time": "2m",
      "unread": 2,
    },
    {
      "convId": 2,
      "name": "Hammad Plumber",
      "last": "Kal 11 baje aa jaunga.",
      "time": "1h",
      "unread": 0,
    },
    {
      "convId": 3,
      "name": "Sara Cleaner",
      "last": "Price final 2500, confirm?",
      "time": "Yesterday",
      "unread": 1,
    },
  ];

  static final messages = [
    {"me": false, "text": "Assalam o Alaikum, job details share kar dein."},
    {"me": true, "text": "Walaikum salam. Pipe leak washbasin ke neeche."},
    {"me": false, "text": "Theek, 30 mins me aa jata hun."},
    {"me": true, "text": "Ok 👍"},
  ];

  static final notifications = [
    {
      "id": 1,
      "title": "Bid Received",
      "body": "You got 2 new bids on 'Bathroom pipe leakage'.",
      "time": "5m",
      "read": false,
    },
    {
      "id": 2,
      "title": "Job Updated",
      "body": "Worker marked job as In Progress.",
      "time": "2h",
      "read": true,
    },
    {
      "id": 3,
      "title": "Payment",
      "body": "Your payment was processed successfully.",
      "time": "Yesterday",
      "read": true,
    },
  ];
}
