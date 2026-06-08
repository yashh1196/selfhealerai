const functions = require("firebase-functions");
const axios = require("axios");

exports.createJiraOnCrash = functions.https.onRequest(async (req, res) => {
  try {
    const payload = req.body;

    // ✅ Safe crashlytics parsing (NO optional chaining)
    let crashData = {};
    if (
      payload &&
      payload.data &&
      payload.data.crashlytics
    ) {
      crashData = payload.data.crashlytics;
    }

    const title = crashData.issueTitle || "Crash detected";
    const url = crashData.issueUrl || "No URL";
    const count = crashData.eventCount || 0;

    // ✅ Jira API call
    const jiraResponse = await axios.post(
      "https://yashpc815.atlassian.net/rest/api/3/issue",
      {
        fields: {
          project: { key: "SHAI" },
          summary: "[Crash] " + title,
          description:
            "Crash Details:\n\n" +
            "Title: " + title + "\n" +
            "URL: " + url + "\n" +
            "Count: " + count,
          issuetype: { name: "Bug" }
        }
      },
      {
        auth: {
          username: "y.ashpc815@gmail.com",
          password: "ATATT3xFfGF0qhhwumB3l8ndHf9M0FJH9PfYrOv8doKlaQyX29GIFakWO_HKWkiaUgNMcaU5mK6AfKLNI9MuCAH-_tshRguYOVHIFL9xzgKEghi54z7DE3VKV0edINqpTgTQj_ZI9Z8dy7TsY7VAbaZUH-6Ma4n7wnr5AeQxmH3URbj83u7nAeY=9336686C"
        },
        headers: {
          "Content-Type": "application/json"
        }
      }
    );

    console.log("Jira ticket created:", jiraResponse.data.key);

    res.status(200).send("Ticket Created Successfully");
  } catch (error) {
    console.error("Error:", error.message);
    res.status(500).send("Error creating ticket");
  }
});



